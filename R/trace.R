the <- new.env(parent = emptyenv())

# The traces of one traced unit are a "scope": a package namespace (named like
# the package) or the anonymous scope "" of the in-process APIs such as
# `with_coverage()`. A process can load several instrumented packages, e.g. a
# package and one that imports it, so each scope has its own traced
# environment, replacements and counters file in `the$scopes`, and the keys of
# its traces are prefixed with its name (see `scope_prefix()`), as files of
# different packages can have the same name. `the$scope` is the scope being
# traced.
the$scopes <- new.env(parent = emptyenv())
the$scope <- ""

# The state of `scope`: `env`, the environment that is traced, `replacements`,
# and `counters_file` and `counters_keys`, from which the counters were
# restored (see `restore_counters()`).
scope_entry <- function(scope) {
  # An environment can't have a binding with an empty name
  id <- if (nzchar(scope)) scope else "<anonymous>"
  entry <- the$scopes[[id]]
  if (is.null(entry)) {
    entry <- new.env(parent = emptyenv())
    the$scopes[[id]] <- entry
  }
  entry
}

# The scope of the traces of the functions in `env`
env_scope <- function(env) {
  if (isNamespace(env)) unname(getNamespaceName(env)) else ""
}

# Trace the functions in `env` into `scope`, the name of its package or "" for
# an environment that is not a package.
trace_environment <- function(env, scope = "") {
  # The counters of the functions are named by the scope they are created in
  old_scope <- the$scope
  the$scope <- scope
  on.exit(the$scope <- old_scope)

  # Tracing an environment that is already traced, e.g. when
  # `pkgload::load_all()` re-fires the onLoad hook, keeps the counts and only
  # instruments the functions that are not instrumented yet, such as functions
  # added or replaced since (#641). Other scopes are never touched.
  entry <- scope_entry(scope)
  if (!identical(entry$env, env)) {
    clear_counters(scope)
    entry$replacements <- list()
  }

  replacements <- compact(c(
    replacements_S4(env),
    replacements_RC(env),
    replacements_R6(env),
    replacements_S7(env),
    replacements_box(env),
    lapply(inactive_names(env), replacement, env = env)
  ))
  if (isTRUE(getOption("covr.full_traversal", FALSE))) {
    replacements <- c(replacements, replacements_nested(env, replacements))
  }
  # Keep the earlier replacements, which hold the originals of the functions
  # traced before.
  entry$replacements <- c(entry$replacements, replacements)
  entry$env <- env

  invisible(lapply(replacements, replace))
}

# The function that the counters added by `trace_calls()` call: the `.Call`
# symbol, or `base::.Call` if a `.Call` function found from `env` would be
# called in place of the primitive, e.g. one that a package defines to wrap
# the calls to its compiled code, as parzer does. `replacement()` checks this
# once for each traced function, from its enclosing environment, which is
# cheaper than looking up `base::.Call` in every count.
dot_call <- function(env) {
  fun <- get0(".Call", envir = env, mode = "function")
  if (is.null(fun) || identical(fun, base::.Call)) {
    as.symbol(".Call")
  } else {
    quote(base::.Call)
  }
}

# Undo the tracing of one scope, or of all scopes if `scope` is `NULL`.
reset_traces <- function(scope = NULL) {
  entries <- if (is.null(scope)) {
    as.list(the$scopes, all.names = TRUE)
  } else {
    list(scope_entry(scope))
  }
  for (entry in entries) {
    entry$env <- NULL
    # Undo in reverse order, so a function replaced more than once ends up
    # with the original from its first replacement.
    lapply(rev(entry$replacements), reset)
  }
  invisible()
}

# Trace files are written under a temporary name and renamed into place, so
# `merge_coverage()` never sees a partially written `covr_trace_*` file. The
# temporary prefix intentionally does not match `^covr_trace_`: leftovers from
# a process killed mid-write are simply ignored.
#
# If serializing the counters fails (e.g. with ALTREP vectors, #509), or the
# process can't count the code it runs (`the$trace_error`, see
# `check_saved_dot_call()`), an error marker is written instead, so the main
# process can report it.
save_trace <- function(directory, scope = NULL) {
  final_file <- temp_file("covr_trace_", tmpdir = directory)
  tmp_file <- temp_file(".covr_tmp_", tmpdir = directory)
  on.exit(unlink(tmp_file, expand = FALSE), add = TRUE)

  sync_counts()
  tryCatch(
    {
      if (!is.null(the$trace_error)) {
        stop(the$trace_error, call. = FALSE)
      }
      save_rds(process_trace(scope), tmp_file)
    },
    error = function(e) {
      marker <- structure(
        list(message = conditionMessage(e), pid = Sys.getpid()),
        class = "covr_trace_error"
      )
      save_rds(marker, tmp_file)
    }
  )
  if (!file.rename(tmp_file, final_file)) {
    covr_abort("Can't write trace file {.path {final_file}}.")
  }
  invisible(final_file)
}

# The trace of `scope` in this process, or of all scopes if it is `NULL`. Each
# package has its own scope, so a process that loads several instrumented
# packages saves the traces of each package with its own finalizer, and a
# package never saves the traces of another one (#786).
#
# A process that restored the counters of a package
# instrumented after it was installed (see `restore_counters()`) only saves the
# non-zero counts of these, by key, with the file it restored them from, from
# which `merge_coverage()` reads their source references. Saving them all
# took 0.4 s and 1 MB per process for a large package, whose tests can start
# hundreds of processes (#744). Other counters, e.g. of functions instrumented
# when the package was loaded, are saved as they are, as are all counters
# when recording tests or measuring branch coverage, which record more than
# the values of the counters.
process_trace <- function(scope = NULL) {
  if (is.null(scope)) {
    return(portable_srcfiles(.counters))
  }
  entry <- scope_entry(scope)
  counters <- scope_counters(scope)
  keys <- entry$counters_keys
  if (
    is.null(keys) ||
      isTRUE(getOption("covr.record_tests", FALSE)) ||
      !is.null(counters[["tests"]]) ||
      !is.null(counters[["branches"]])
  ) {
    return(portable_srcfiles(counters))
  }
  # A numeric vector named by key, without the counters that have no value
  counts <- c(
    numeric(),
    unlist(lapply(
      mget(keys, envir = .counters, ifnotfound = list(NULL)),
      .subset2,
      "value"
    ))
  )
  # The other traces of the scope, which are saved as they are
  others <- counters[setdiff(names(counters), keys)]
  structure(
    list(
      counters_file = entry$counters_file,
      counts = counts[counts != 0],
      counters = portable_srcfiles(others)
    ),
    class = "covr_counts"
  )
}

save_rds <- function(object, file) {
  saveRDS(object, file = file)
}

# Returns a copy of `x` in which the srcfiles are replaced by `copy_srcfile()`.
#
# The srcfiles of an installed package are restored from its lazy-load
# database, with promises to load their `lines` and `parseData`. These are
# evaluated in an environment that references every environment restored from
# the database, such as environments in the package namespace and the closure
# environments of objects created when the package was built. Saving the
# promises would save the contents of all of these environments too, which can
# be large, and crashes R if they hold objects that were already finalized when
# the trace is saved on exit, e.g. data read with arrow (#602).
#
# The srcfiles are found by the reference hook of `serialize()`, so they are
# replaced wherever they are, e.g. in the calls of recorded tests.
portable_srcfiles <- function(x) {
  srcfiles <- list()
  serialized <- serialize(x, NULL, refhook = function(env) {
    if (inherits(env, "srcfile")) {
      id <- address(env)
      srcfiles[[id]] <<- env
      id
    }
  })
  copies <- new.env(parent = emptyenv())
  unserialize(serialized, refhook = function(id) {
    copy_srcfile(srcfiles[[id]], copies)
  })
}

# A copy of `srcfile` that only holds what is needed to report coverage: its
# atomic values, such as its file name and lines, and copies of the srcfiles it
# references, such as the `original` of a `srcfilealias`. Its parse data and
# anything packages added to it are left out, e.g. this.path adds an
# environment with a promise referencing the srcfile. Only R's promise to
# load `lines` is forced; other promises and active bindings could run
# arbitrary code while R exits.
#
# `copies` holds the copies made so far by the address of their srcfile, so
# the srcfiles of the files of a package share the copy of the srcfile they are
# an alias of, which holds the lines of all the files. A copy is added before
# its bindings are copied, so srcfiles that reference each other don't recurse
# forever.
copy_srcfile <- function(srcfile, copies) {
  id <- address(srcfile)
  if (!is.null(copies[[id]])) {
    return(copies[[id]])
  }
  copy <- new.env(parent = emptyenv())
  class(copy) <- class(srcfile)
  copies[[id]] <- copy
  for (name in setdiff(ls(srcfile, all.names = TRUE), "parseData")) {
    if (
      bindingIsActive(name, srcfile) ||
        (name != "lines" && is_unforced_promise(srcfile, name))
    ) {
      next
    }
    value <- get(name, envir = srcfile, inherits = FALSE)
    if (is.environment(value) && inherits(value, "srcfile")) {
      assign(name, copy_srcfile(value, copies), envir = copy)
    } else if (
      is.null(value) ||
        is.atomic(value) &&
          all(vapply(attributes(value), is.atomic, logical(1)))
    ) {
      assign(name, value, envir = copy)
    }
  }
  copy
}

# Called from the loader script of the instrumented package (see `add_hooks()`)
# while its namespace is loaded. The finalizer saves the trace of the scope of
# the package (its name) when the namespace is garbage collected or R exits
# normally; other packages instrumented in the process have their own
# finalizer and trace. Until then a
# `covr_pending_<pid>_*` marker exists in `directory`, so `package_coverage()`
# can report processes that loaded the package but never saved their trace,
# e.g. because they were killed (#438). Markers are owned by the process whose
# pid is in their name; forked children inherit the finalizer but not the
# parent's markers, so `save_trace_and_clear()` leaves those alone.
#
# `directory` (from `COVR_TRACE_DIR` or `COVERAGE_DIR`) is fixed when the
# package loads, so the marker and the trace end up in the same place. A marker
# that can't be created is not worth a warning during package load; the trace
# save fails later too.
register_trace <- function(ns, directory, scope = env_scope(ns)) {
  force(scope)
  pid <- Sys.getpid()
  pending <- temp_file(paste0("covr_pending_", pid, "_"), tmpdir = directory)
  suppressWarnings(file.create(pending))
  reg.finalizer(
    ns,
    function(...) save_trace_and_clear(directory, scope),
    onexit = TRUE
  )
  invisible(pending)
}

# Also used by the patched `parallel:::mcexit()` (see `fix_mcexit()`), as forked
# workers exit without running finalizers. A worker that loads the package after
# forking creates its own marker, which is removed here.
save_trace_and_clear <- function(directory, scope = NULL) {
  res <- save_trace(directory, scope)
  unlink(
    list.files(
      directory,
      pattern = pending_pattern(Sys.getpid()),
      full.names = TRUE
    ),
    expand = FALSE
  )
  invisible(res)
}

pending_pattern <- function(pid) {
  paste0("^covr_pending_", pid, "_")
}

# The markers of processes that loaded the package but did not save their
# trace. Markers of this process are ignored; it can load the instrumented
# package (e.g. for a `\Sexpr` in an example) but only saves its trace on exit.
unsaved_traces <- function(directory) {
  markers <- list.files(directory, pattern = "^covr_pending_")
  markers[!grepl(pending_pattern(Sys.getpid()), markers)]
}

# Convert a counters object to a coverage object
#
# @param counters An environment of covr trace results to convert to a coverage
#   object.
# @param ... Additional attributes to include with the coverage object.
as_coverage <- function(counters, ...) {
  counters <- as.list(counters)
  counters <- as_coverage_with_tests(counters)

  names(counters) <- unscope_keys(names(counters))
  branches <- attr(counters, "branches")
  if (!is.null(branches)) {
    names(branches) <- unscope_keys(names(branches))
    attr(counters, "branches") <- branches
  }

  structure(counters, ..., class = "coverage")
}

# The keys of the traces of a package start with its name (see
# `scope_prefix()`), which isn't part of the names of a coverage object. The
# prefix is kept on keys that would otherwise have the same name as another
# trace, e.g. of a file with the same name in another package loaded in the
# process, as traces are merged by name.
unscope_keys <- function(keys) {
  if (is.null(keys)) {
    return(keys)
  }
  stripped <- sub("^[^/]*/", "", keys)
  same <- duplicated(stripped) | duplicated(stripped, fromLast = TRUE)
  keys[!same] <- stripped[!same]
  keys
}

# Clean and restructure counter tests for a coverage object
#
# For tests produced with `options(covr.record_tests)`, prune any unused
# records in the $tests$tally matrices of each trace and get rid of the
# wrapping $tests environment (reassigning with value of $tests$tally)
as_coverage_with_tests <- function(counters) {
  # `[[` rather than `$` for the elements that are not traces, which would
  # partially match the key of a trace in a file whose name starts with "tests"
  # or "branches"
  branches <- as_branch_list(counters[["branches"]])
  counters[["branches"]] <- NULL
  tests <- counters[["tests"]]
  counters[["tests"]] <- NULL

  clean_coverage_tests(counters)

  # unnest environment-wrapped $tests$tally as more accessible $tests
  for (i in seq_along(counters)) {
    if (!is.environment(counters[[i]]$tests)) {
      next
    }
    counters[[i]]$tests <- counters[[i]]$tests$tally
  }

  structure(
    counters,
    tests = tests,
    branches = branches,
    class = "coverage"
  )
}
