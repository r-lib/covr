#' Calculate test coverage for a Shiny app
#'
#' Measures the coverage of the functions of a Shiny app that is not part of a
#' package, while `code` runs its tests, by default with
#' [shinytest2::test_app()]. This includes the code run by the app in the R
#' processes that \pkg{shinytest2} starts to run it. For apps in a package, use
#' [package_coverage()] instead.
#'
#' @details
#' The functions defined by the app's files (`app.R`, `ui.R`, `server.R`,
#' `global.R` and the files in `R/`) are instrumented when Shiny loads them,
#' in this R process and in the R processes started while `code` runs. This
#' includes a server function that isn't assigned to a name, such as the one
#' in `server.R` or one defined inline, e.g. `shinyApp(ui, function(input,
#' output) ...)`. Code outside functions, such as building the UI, is not
#' counted, as in [package_coverage()].
#'
#' This works by adding covr to the default packages of R processes started
#' while `code` runs (the `R_DEFAULT_PACKAGES` environment variable), and
#' relies on internal hooks of Shiny which may change in future versions.
#'
#' An app process saves its coverage when it exits normally, so stop it
#' gracefully, e.g. with `$stop()` on a \pkg{shinytest2} `AppDriver`, which
#' waits longer for the app to exit when run by covr. If an app process is
#' killed or is still running when `code` finishes, its coverage is lost and
#' `shiny_app_coverage()` warns (with class `covr_unsaved_trace`).
#'
#' `AppDriver$new()` skips tests on CRAN unless the `NOT_CRAN` environment
#' variable is `"true"`.
#'
#' @param app_dir The directory of the Shiny app.
#' @param code The code to run the app's tests, evaluated in the calling
#'   environment.
#' @inheritParams file_coverage
#' @returns A [coverage] object.
#' @seealso `vignette("shiny", package = "covr")`
#' @examples
#' \dontrun{
#' Sys.setenv(NOT_CRAN = "true")
#' shiny_app_coverage("path/to/app")
#' }
#' @export
shiny_app_coverage <- function(
  app_dir = ".",
  code = shinytest2::test_app(app_dir),
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  if (!is_installed("shiny")) {
    covr_abort("{.pkg shiny} must be installed to measure Shiny app coverage.")
  }
  app_dir <- normalize_path(app_dir)
  if (!dir.exists(app_dir)) {
    covr_abort("Can't find the Shiny app directory {.path {app_dir}}.")
  }

  trace_dir <- temp_file("covr_shiny_")
  dir.create(trace_dir)

  clear_counters()
  the$shiny_app_dir <- app_dir
  untrace_source <- trace_shiny_source()
  restore_forks <- if (should_enable_parallel_mcexit_fix()) {
    trace_forks(trace_dir)
  } else {
    function() invisible()
  }
  on.exit({
    restore_forks()
    untrace_source()
    lapply(rev(the$shiny_replacements), reset)
    the$shiny_replacements <- list()
    the$shiny_app_dir <- NULL
    clear_counters()
    unlink(trace_dir, recursive = TRUE)
  })

  withr::with_envvar(
    c(
      R_DEFAULT_PACKAGES = paste(
        union(getOption("defaultPackages"), "covr"),
        collapse = ","
      ),
      COVR_SHINY_APP = app_dir,
      COVR_SHINY_PID = Sys.getpid(),
      COVERAGE_DIR = trace_dir,
      R_COVR = "true"
    ),
    code
  )

  sync_counts()
  counters <- as.list(.counters)
  counters <- merge_traces(trace_dir, counters)

  warn_unsaved_traces(
    trace_dir,
    "ran the Shiny app",
    "Did a test leave an app running? Stop it with {.code app$stop()}."
  )

  exclude(
    as_coverage(counters, root = app_dir),
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = app_dir
  )
}

# Called from `.onAttach()` in the R processes started by
# `shiny_app_coverage()`, which attach covr as one of their default packages.
# The trace is only registered (see `register_trace()`) once a function of the
# app is instrumented, so other R processes, e.g. a callr session that never
# runs the app, don't save empty traces or leave markers behind.
start_shiny_app_tracing <- function(app_dir, trace_dir, attach_env) {
  the$shiny_app_dir <- app_dir
  the$shiny_trace_dir <- trace_dir

  # Shiny calls `registerShinyDebugHook()`, if it can find one, with each
  # server function it starts and each function created by its render and
  # reactive functions; RStudio uses it to set breakpoints. Shiny looks it up
  # from its namespace, which reaches the attached packages, so it is put in
  # covr's package environment, which isn't locked yet in `.onAttach()`.
  assign(
    "registerShinyDebugHook",
    function(params) instrument_shiny_function(params$name, params$where),
    envir = attach_env
  )

  if (shiny_loaded()) {
    trace_shiny_source()
  } else {
    setHook(
      packageEvent("shiny", "onLoad"),
      function(...) trace_shiny_source()
    )
  }
  invisible()
}

# A mockable `isNamespaceLoaded()`, so tests can take the branch that waits
# for Shiny to load.
shiny_loaded <- function() {
  isNamespaceLoaded("shiny")
}

# Shiny sources the files of an app with its internal `sourceUTF8(file,
# envir)`, keeping their srcrefs. The functions they define, and the server
# function they return, are instrumented when it returns. Returns a function
# that restores `sourceUTF8()` as it was before, e.g. traced by the user.
trace_shiny_source <- function(
  original = asNamespace("shiny")$sourceUTF8
) {
  shiny <- asNamespace("shiny")
  if (!all(c("file", "envir") %in% names(formals(original)))) {
    covr_warn(c(
      "Can't instrument the files of the Shiny app.",
      i = "This version of {.pkg shiny} is not supported by covr."
    ))
    return(function() invisible())
  }
  suppressMessages(trace(
    "sourceUTF8",
    exit = as.call(list(
      instrument_shiny_source,
      quote(file),
      quote(envir),
      quote(returnValue())
    )),
    where = shiny,
    print = FALSE
  ))
  function() replace_binding("shiny", "sourceUTF8", original)
}

instrument_shiny_source <- function(file, env, value) {
  if (!in_shiny_app(normalize_path(file))) {
    return(invisible())
  }
  for (name in ls(env, all.names = TRUE)) {
    if (!bindingIsActive(name, env)) {
      instrument_shiny_function(name, env)
    }
  }
  # A server function that isn't bound to a name, e.g. the value of
  # `server.R` or defined inline in `shinyApp()` in `app.R`. Shiny's debug hook
  # only sees it when a session starts, not in `testServer()`.
  if (inherits(value, "shiny.appobj")) {
    instrument_shiny_function("server", environment(value$serverFuncSource))
  } else if (is.function(value)) {
    instrument_shiny_function("server", env, value)
  }
  invisible()
}

# Instruments the function `fun` (by default `name` in `env`) in place if it
# was defined in a file of the app and is not instrumented yet, e.g. because
# it was already instrumented when its file was sourced, or was created from
# instrumented code by a render function.
instrument_shiny_function <- function(
  name,
  env,
  fun = get0(name, envir = env, inherits = FALSE)
) {
  if (!is.function(fun) || is.primitive(fun)) {
    return(invisible())
  }
  if (
    !in_shiny_app(get_source_filename(fun, full.names = TRUE, normalize = TRUE))
  ) {
    return(invisible())
  }
  replacement <- replacement(name, env = env, target_value = fun)
  if (is.null(replacement)) {
    return(invisible())
  }

  if (!is.null(the$shiny_trace_dir) && !isTRUE(the$shiny_trace_registered)) {
    register_trace(asNamespace("covr"), the$shiny_trace_dir)
    # Forked processes, e.g. from `parallel::mclapply()`, exit without running
    # the finalizer that saves the trace.
    if (should_enable_parallel_mcexit_fix()) {
      trace_forks(the$shiny_trace_dir)
    }
    the$shiny_trace_registered <- TRUE
  }
  the$shiny_replacements <- c(the$shiny_replacements, list(replacement))
  replace(replacement)
  invisible()
}

in_shiny_app <- function(file) {
  !is.null(the$shiny_app_dir) &&
    nzchar(file) &&
    startsWith(file, paste0(the$shiny_app_dir, "/"))
}
