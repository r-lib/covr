# Instrument and byte-compile an installed package once, rather than every time
# a process loads it.
#
# `package_coverage()` installs the package without byte-compiling it, then
# starts an R process (see `instrument_installed_package()`) that loads the
# namespace from the lazy-load database that `R CMD INSTALL` wrote, as
# `tools:::code2LazyLoadDB()` does when it builds the database, instruments
# and byte-compiles its functions in place and writes the database again, next
# to the original. The keys, source references and functions of the traces are
# saved with it, and the loader script (see `add_hooks()`) reads that database
# and restores the counters instead of tracing the namespace each time it is
# loaded.
# Instrumented code identifies its trace by the key string, so it can be saved
# in the database (see `covr_count()` in src/count.c).

# Run `instrument_installed_package()` in a new R process, like `R CMD
# INSTALL` is run, as it loads the package. Returns the file with the counters
# of the traces, or `NULL` if the package is left as installed and should be
# instrumented when it is loaded: with a warning if the process failed.
instrument_package <- function(
  pkg,
  install_path,
  record_tests = isTRUE(getOption("covr.record_tests", FALSE)),
  full_traversal = FALSE,
  branch_coverage = isTRUE(getOption("covr.branch_coverage", FALSE))
) {
  args <- c(
    "--vanilla",
    "--no-echo",
    "-e",
    shQuote("covr:::instrument_main()"),
    "--args",
    shQuote(c(
      pkg$package,
      install_path,
      record_tests,
      isTRUE(full_traversal),
      branch_coverage
    ))
  )
  name <- if (.Platform$OS.type == "windows") "R.exe" else "R"
  output <- withr::with_envvar(
    c(
      R_DEFAULT_PACKAGES = "datasets,utils,grDevices,graphics,stats,methods",
      R_LIBS = env_path(install_path, .libPaths())
    ),
    suppressWarnings(system2(
      file.path(R.home("bin"), name),
      args,
      stdout = TRUE,
      stderr = TRUE
    ))
  )
  status <- attr(output, "status") %||% 0L
  file <- instrumented_counters_file(pkg$package, install_path)
  if (status == 0L && file.exists(file)) {
    return(file)
  }
  # The package can't be instrumented ahead of time
  if (!identical(status, instrument_skipped)) {
    covr_warn(
      c(
        "Can't instrument the installed package {.pkg {pkg$package}} ahead of time.",
        i = "It is instrumented each time it is loaded instead.",
        i = "Output: {.val {utils::tail(output, failure_lines())}}"
      ),
      class = "covr_instrument_failed"
    )
  }
  NULL
}

# Whether a package is instrumented after it is installed, rather than when it
# is loaded: `options(covr.install_instrument = FALSE)`, or the environment
# variable `COVR_INSTALL_INSTRUMENT=false`.
install_instrument <- function() {
  install_setting("covr.install_instrument", "COVR_INSTALL_INSTRUMENT")
}

# A logical option, which is `TRUE` unless the environment variable is false.
install_setting <- function(option, envvar) {
  getOption(
    option,
    !tolower(Sys.getenv(envvar, "true")) %in% c("false", "f", "no", "0")
  )
}

# The exit status of the process that instruments a package when it leaves the
# package as installed.
instrument_skipped <- 2L

# The base of the lazy-load database of the instrumented code, next to the
# database of the installed code.
instrumented_db_base <- function(pkg_name, lib) {
  file.path(lib, pkg_name, "R", paste0(pkg_name, ".covr"))
}

instrumented_counters_file <- function(pkg_name, lib) {
  file.path(lib, pkg_name, "R", "covr_counters.rds")
}

# The entry point of the process started by `instrument_package()`.
instrument_main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  options(
    covr.record_tests = as.logical(args[[3]]),
    covr.full_traversal = as.logical(args[[4]]),
    covr.branch_coverage = as.logical(args[[5]])
  )
  if (
    !instrument_installed_package(
      args[[1]],
      args[[2]]
    )
  ) {
    quit(save = "no", status = instrument_skipped)
  }
  invisible()
}

# Instrument and byte-compile the functions of the installed package
# `pkg_name` in the library `lib`, rewrite its lazy-load database with them
# and save the counters. Returns `FALSE`, leaving the package as installed, if
# its namespace is not just what is in the database.
instrument_installed_package <- function(pkg_name, lib) {
  base <- file.path(lib, pkg_name, "R", pkg_name)
  if (
    !file.exists(paste0(base, ".rdb")) || has_sysdata_functions(pkg_name, lib)
  ) {
    return(FALSE)
  }

  # Like `tools:::code2LazyLoadDB()`, this doesn't run `.onLoad()` or load
  # the package's compiled code.
  ns <- suppressPackageStartupMessages(
    loadNamespace(pkg_name, lib.loc = lib, partial = TRUE)
  )
  register_namespace(pkg_name, ns)
  trace_environment(ns)
  compiled <- !isFALSE(package_byte_compile(pkg_name, lib))
  if (compiled) {
    compile_replacements(the$replacements)
  }

  # The functions hold promises that read the original database, which is left
  # as it is: the new one is written next to it, and the loader script that
  # `add_hooks()` writes reads it. A process that fails before then leaves a
  # package that still works as installed.
  new_base <- instrumented_db_base(pkg_name, lib)
  counters_file <- instrumented_counters_file(pkg_name, lib)
  done <- FALSE
  on.exit(
    if (!done) unlink(c(paste0(new_base, c(".rdb", ".rdx")), counters_file)),
    add = TRUE
  )
  compress <- readRDS(paste0(base, ".rdx"))$compressed
  make_lazy_load_db <- get("makeLazyLoadDB", envir = asNamespace("tools"))
  make_lazy_load_db(ns, new_base, compress = compress)
  counters <- portable_srcfiles(.counters)
  # Whether a `.Call` that `.onLoad()` defines would mask the saved counters,
  # for `restore_counters()`. Byte-compiled code calls the `.Call` primitive
  # directly, as the compiler inlines base functions that the namespace
  # doesn't define, and counters that record tests don't call `.Call`.
  attr(counters, "maskable") <- !compiled &&
    !isTRUE(getOption("covr.record_tests", FALSE)) &&
    identical(dot_call(ns), as.symbol(".Call"))
  saveRDS(counters, counters_file)
  done <- TRUE
  TRUE
}

# `loadNamespace()` unregisters the namespace when it returns after loading the
# code of a package, as it only does that to write the lazy-load database. The
# functions in the database are only read when they are first used, and refer
# to their namespace by name, so without it a full `loadNamespace()` of the
# package, which runs `.onLoad()` and loads its compiled code, would give them a
# second namespace. There is no other way to register a namespace than the
# internal function that `loadNamespace()` uses.
register_namespace <- function(pkg_name, ns) {
  eval(as.call(list(
    as.name(".Internal"),
    as.call(list(as.name("registerNamespace"), pkg_name, ns))
  )))
  invisible()
}

# Functions in `R/sysdata.rda` are only in the namespace once it is loaded, so
# they can't be instrumented in the lazy-load database of the code.
has_sysdata_functions <- function(pkg_name, lib) {
  base <- file.path(lib, pkg_name, "R", "sysdata")
  if (!file.exists(paste0(base, ".rdb"))) {
    return(FALSE)
  }
  if (isTRUE(getOption("covr.full_traversal"))) {
    return(TRUE)
  }
  env <- new.env()
  lazyLoad(base, env)
  for (name in ls(env, all.names = TRUE)) {
    x <- env[[name]]
    if (is.function(x) || is.environment(x) || isS4(x)) {
      return(TRUE)
    }
  }
  FALSE
}

# The `ByteCompile` field of the package as `R CMD INSTALL` reads it, or `NA`
# if it has none.
package_byte_compile <- function(pkg_name, lib) {
  desc <- readRDS(file.path(lib, pkg_name, "Meta", "package.rds"))$DESCRIPTION
  value <- trimws(desc["ByteCompile"])
  if (value %in% c("1", "yes", "Yes", "true", "True", "TRUE", "T")) {
    TRUE
  } else if (value %in% c("0", "no", "No", "false", "False", "FALSE", "F")) {
    FALSE
  } else {
    NA
  }
}

# Byte-compile the instrumented functions in place, so that references to them,
# e.g. from methods tables and R6 generators, keep their compiled versions.
compile_replacements <- function(replacements) {
  for (r in replacements) {
    compile_in_place(r$target_value)
    # The functions of wrappers, see `replacement()`
    inner <- if (is_vectorized(r$target_value)) {
      "FUN"
    } else if (inherits(r$target_value, "memoised")) {
      "_f"
    }
    if (!is.null(inner)) {
      compile_in_place(environment(r$target_value)[[inner]])
    }
  }
  invisible()
}

compile_in_place <- function(fun) {
  if (is.function(fun) && !is.primitive(fun)) {
    compiled <- tryCatch(compiler::cmpfun(fun), error = function(e) NULL)
    if (is.function(compiled)) {
      .Call(covr_reassign_function, fun, compiled)
    }
  }
  invisible()
}

# Called from the loader script of an instrumented package (see
# `add_hooks()`), in place of `trace_environment()`: the counters of the traces
# in the code that was saved by `instrument_installed_package()`.
#
# The hook runs after `.onLoad()`, which can create or replace functions in the
# namespace (e.g. with `assign()`, `delayedAssign()` or `memoise::memoise()`).
# These are not in the saved code, so `trace_environment()` instruments the
# functions that are not instrumented yet, as when the namespace is loaded
# again by `pkgload::load_all()`. The same happens for a package that is
# loaded again in the same process. Bindings that are still promises to read
# the saved code are not forced for that, which would read all the functions
# of the package.
restore_counters <- function(ns, file) {
  # The loader script reads the instrumented code, which needs its counters.
  if (!file.exists(file)) {
    covr_abort(
      "Can't find the counters of the instrumented package at {.path {file}}."
    )
  }
  # As in `trace_environment()`, the counters of a namespace that is already
  # restored are kept.
  if (identical(the$traced_env, ns)) {
    return(invisible())
  }
  saved <- readRDS(file)
  check_saved_dot_call(ns, saved)
  if (file %in% the$restored) {
    trace_unforced_environment(ns)
    add_saved_counters(saved)
  } else {
    clear_counters()
    the$replacements <- list()
    the$restored <- c(the$restored, file)
    add_saved_counters(saved)
    # For `process_trace()`, which only saves the counts of these counters
    the$counters_file <- file
    the$counters_keys <- setdiff(
      ls(saved, all.names = TRUE),
      c("tests", "branches")
    )
    the$traced_env <- ns
    trace_unforced_environment(ns)
  }
  invisible()
}

# The saved code was instrumented before `.onLoad()` ran, so unless it was
# byte-compiled or the package's R code defines `.Call` (see `dot_call()`), its
# counters call `.Call` by name. A `.Call` function that `.onLoad()` defines
# would be called by them instead, so this is an error. Errors in onLoad hooks
# are only printed, as `loadNamespace()` runs them in `try()`, so it is also
# saved in place of the trace of the process (see `save_trace()`), which
# `package_coverage()` reports.
check_saved_dot_call <- function(ns, saved) {
  if (
    isTRUE(attr(saved, "maskable")) &&
      identical(dot_call(ns), quote(base::.Call))
  ) {
    err <- tryCatch(
      covr_abort(c(
        "Can't measure the coverage of {.pkg {environmentName(ns)}}, as its {.code .onLoad()} defines a {.code .Call} function.",
        i = "The counters that covr added when the package was installed call {.code .Call}, so they would call this function instead of the base one.",
        i = "Define {.code .Call} in the package's R code instead, or set {.code options(covr.install_instrument = FALSE)}."
      )),
      error = identity
    )
    the$trace_error <- conditionMessage(err)
    stop(err)
  }
}

# `trace_environment()` without reading the bindings that are still promises to
# read the saved code, which `.onLoad()` replaces rather than forces.
trace_unforced_environment <- function(ns) {
  the$skip_lazy_load <- TRUE
  on.exit(the$skip_lazy_load <- NULL)
  trace_environment(ns)
}

# Whether `name` in `env` is a promise, that hasn't been forced, to read a
# value from a lazy-load database, as made by `lazyLoad()`, rather than one
# that was made by the package, e.g. with `delayedAssign()`.
is_lazy_load_promise <- function(env, name) {
  is_unforced_promise(env, name) &&
    {
      # The expression of a promise, without forcing it
      expr <- do.call(substitute, list(as.name(name), env))
      is.call(expr) && identical(expr[[1L]], as.name("lazyLoadDBfetch"))
    }
}

# Add the `saved` counters that don't exist yet. The decisions of branch
# coverage are in an environment that can already exist, if functions were
# instrumented since the counters were cleared.
add_saved_counters <- function(saved) {
  counters <- as.list(saved, all.names = TRUE)
  saved_branches <- counters$branches
  counters <- counters[setdiff(
    names(counters),
    ls(.counters, all.names = TRUE)
  )]
  list2env(counters, .counters)
  if (
    is.environment(saved_branches) &&
      !identical(saved_branches, .counters$branches)
  ) {
    branches <- .counters$branches
    for (key in setdiff(
      ls(saved_branches, all.names = TRUE),
      ls(branches, all.names = TRUE)
    )) {
      branches[[key]] <- saved_branches[[key]]
    }
  }
  register_count(names(counters)[
    !vapply(counters, function(x) is.null(x$value), logical(1))
  ])
  invisible()
}
