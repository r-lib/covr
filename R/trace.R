the <- new.env(parent = emptyenv())

# The traces of one traced unit are a "scope": a package namespace (named like
# the package), the Shiny app of `shiny_app_coverage()` (`shiny_scope`), or
# the anonymous scope of the in-process APIs such as `with_coverage()`
# (`anonymous_scope`). A process can load several instrumented packages, e.g. a
# package and one that imports it, so each scope has its own traced
# environment, replacements and counters file in `the$scopes`, and the keys of
# its traces are prefixed with its name (see `scope_prefix()`), as files of
# different packages can have the same name. `the$scope` is the scope being
# traced.
the$scopes <- new.env(parent = emptyenv())

# The scope of `with_coverage()`, `file_coverage()`, `function_coverage()` and
# the other in-process APIs. Its keys have no prefix.
anonymous_scope <- ""
# The scope of the functions of a Shiny app, which can't be a package name.
shiny_scope <- "<shiny>"

the$scope <- anonymous_scope

# The state of `scope`: `env`, the environment that is traced, `replacements`,
# and `counters_file` and `counters_keys`, from which the counters were
# restored (see `restore_counters()`). `untrace_scope()` removes it.
scope_entry <- function(scope) {
  id <- scope_id(scope)
  entry <- the$scopes[[id]]
  if (is.null(entry)) {
    entry <- new.env(parent = emptyenv())
    the$scopes[[id]] <- entry
  }
  entry
}

# An environment can't have a binding with an empty name
scope_id <- function(scope) {
  if (identical(scope, anonymous_scope)) "<anonymous>" else scope
}

# The scope of the traces of the functions in `env`
env_scope <- function(env) {
  if (isNamespace(env)) unname(getNamespaceName(env)) else anonymous_scope
}

# Name the counters created until the calling function returns by `scope`
local_scope <- function(scope, frame = parent.frame()) {
  old_scope <- the$scope
  the$scope <- scope
  withr::defer(the$scope <- old_scope, envir = frame)
}

# Trace the functions in `env` into `scope`, the name of its package or
# `anonymous_scope` for an environment that is not a package.
trace_environment <- function(env, scope = anonymous_scope) {
  local_scope(scope)

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

# Replace one function, outside `trace_environment()`, recording it in `scope`
# so `untrace_scope()` restores it. Create `replacement` in the same scope
# (see `local_scope()`), which names its counters.
trace_replacement <- function(replacement, scope) {
  entry <- scope_entry(scope)
  entry$replacements <- c(entry$replacements, list(replacement))
  replace(replacement)
}

# The in-process APIs all trace into `anonymous_scope`, whose record only
# exists while one of them runs (see `untrace_scope()`). One that runs inside
# another would clear the outer call's counts and restore its functions when
# it ends, so the outer call's tracing is undone first, with a warning. Its
# record is gone after that, so later nested calls in the same outer call
# don't warn again.
untrace_nested_anonymous_scope <- function() {
  id <- scope_id(anonymous_scope)
  if (is.null(get0(id, envir = the$scopes, inherits = FALSE))) {
    return(invisible())
  }
  covr_warn(
    c(
      "Coverage is already being measured by an enclosing call.",
      i = "{.fn with_coverage}, {.fn file_coverage}, {.fn function_coverage}
        and the functions that call them can't be nested; the enclosing
        call's coverage is incomplete."
    ),
    class = "covr_nested_coverage"
  )
  untrace_scope(anonymous_scope)
}

# Undo the tracing of one scope, or of all scopes if `scope` is `NULL`: restore
# the original functions, clear the counters and forget the scope, so nothing
# keeps the traced environment alive and untracing again does nothing.
untrace_scope <- function(scope = NULL) {
  ids <- if (is.null(scope)) {
    ls(the$scopes, all.names = TRUE)
  } else {
    scope_id(scope)
  }
  for (id in ids) {
    entry <- get0(id, envir = the$scopes, inherits = FALSE)
    if (is.null(entry)) {
      next
    }
    rm(list = id, envir = the$scopes)
    # Undo in reverse order, so a function replaced more than once ends up
    # with the original from its first replacement.
    replacements <- entry$replacements
    entry$replacements <- list()
    lapply(rev(replacements), reset)
  }
  clear_counters(scope)
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
      trace <- process_trace(scope)
      if (inherits(trace, "covr_counts")) {
        trace$counters_file <- stage_counters_file(
          trace$counters_file,
          directory
        )
      }
      save_rds(trace, tmp_file)
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

# A copy of the counters `file` of a package instrumented after it was
# installed in the trace `directory`, named by its contents, so the traces in
# the directory can be read without the library, e.g. after the package is
# restored or in another job. Returns the name of the copy, which
# `merge_coverage()` reads relative to the directory of the trace, or `file`
# if it can't be copied.
stage_counters_file <- function(file, directory) {
  md5 <- unname(tools::md5sum(file))
  if (is.na(md5)) {
    return(file)
  }
  name <- paste0("covr_counters_", md5, ".rds")
  dest <- file.path(directory, name)
  if (!file.exists(dest)) {
    tmp <- temp_file(".covr_tmp_", tmpdir = directory)
    on.exit(unlink(tmp, expand = FALSE), add = TRUE)
    if (!file.copy(file, tmp) || !file.rename(tmp, dest)) {
      return(file)
    }
  }
  name
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

# The directory instrumented packages save their traces in: the environment
# variable `COVR_TRACE_DIR`, or `default` if it is unset or empty.
trace_dir_setting <- function(default) {
  dir <- Sys.getenv("COVR_TRACE_DIR")
  if (nzchar(dir)) dir else default
}

# Called from the loader script of the instrumented package (see `add_hooks()`)
# while its namespace is loaded. The finalizer saves the trace of the scope of
# the package (its name) when the namespace is garbage collected or R exits
# normally; other packages instrumented in the process have their own
# finalizer and trace. Until then a
# `covr_pending_<pid>_<package>_*` marker exists in `directory`, so
# `package_coverage()` can report processes that loaded the package but never
# saved its trace, e.g. because they were killed (#438). Markers are owned by
# the process whose pid is in their name; forked children inherit the
# finalizer but not the parent's markers, so `save_trace_and_clear()` leaves
# those alone.
#
# `directory` (from `COVR_TRACE_DIR`) is fixed when the package loads, so the
# marker and the trace end up in the same place. A marker that can't be created
# is not worth a warning during package load; the trace save fails later too.
register_trace <- function(ns, directory, scope = env_scope(ns)) {
  force(scope)
  pending <- temp_file(
    paste0("covr_pending_", Sys.getpid(), "_", marker_scope(scope)),
    tmpdir = directory
  )
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
# forking creates its own marker, which is removed here. Only the markers of
# `scope` are removed, so a process that is killed after saving the trace of
# one package still has the markers of the others.
save_trace_and_clear <- function(directory, scope = NULL) {
  res <- save_trace(directory, scope)
  unlink(
    list.files(
      directory,
      pattern = pending_pattern(Sys.getpid(), scope),
      full.names = TRUE
    ),
    expand = FALSE
  )
  invisible(res)
}

# The part of the name of the markers of `scope`: the name of a package, or
# nothing for other scopes, whose names can't be in file names.
marker_scope <- function(scope) {
  if (is.character(scope) && grepl("^[[:alnum:].]+$", scope)) {
    paste0(scope, "_")
  } else {
    ""
  }
}

pending_pattern <- function(pid, scope = NULL) {
  paste0(
    "^covr_pending_",
    pid,
    "_",
    gsub(".", "\\.", marker_scope(scope), fixed = TRUE)
  )
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
