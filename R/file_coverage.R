#' Calculate test coverage for sets of files
#'
#' The files in `source_files` are first sourced into a new environment
#' to define functions to be checked. Then they are instrumented to track
#' coverage and the files in `test_files` are run with `runner`.
#' @param source_files Character vector of source files with function
#'   definitions to measure coverage. Can also include compiled files from a
#'   package's `src/` directory; see the compiled code section.
#' @param test_files Character vector of test files with code to test the
#'   functions
#' @param parent_env The parent environment to use when sourcing the files.
#'   If `source_files` includes compiled files, the default is the namespace
#'   of their package.
#' @param runner A function used to run each test file, called as
#'   `runner(file, env = env)`, where `env` is the environment the
#'   `source_files` were sourced into. The default sources the file into `env`
#'   with [sys.source()]. Use `runner = testthat::test_file` to run testthat
#'   tests with testthat's test runner; see the testthat tests section.
#' @inheritParams package_coverage
#' @section Parallel code:
#' Code run in processes forked by [parallel::mclapply()],
#' `parallel::mcparallel()` and related functions (not available on Windows)
#' is included in the coverage. While the code runs, `parallel:::mcfork` and
#' `parallel:::mcexit` are patched so that the forked processes save their
#' counts when they exit. To turn this off, set the option
#' `covr.fix_parallel_mcexit` or the environment variable
#' `COVR_FIX_PARALLEL_MCEXIT` to `FALSE`.
#' @section testthat tests:
#' By default the test files are run with [sys.source()], not with testthat's
#' test runner, so features that need the runner don't work. In particular,
#' `testthat::expect_snapshot()` is skipped ("Can't compare snapshot to
#' reference when testing interactively").
#'
#' To use these features, run the test files with [testthat::test_file()]:
#'
#' ```r
#' file_coverage(
#'   "R/my_functions.R",
#'   "tests/test-my_functions.R",
#'   runner = testthat::test_file
#' )
#' ```
#'
#' The tests then run in a child of the environment the source files were
#' sourced into, and snapshots are saved in a `_snaps` directory next to the
#' test file. `expect_snapshot()` also needs testthat's 3rd edition (e.g.
#' `testthat::local_edition(3)` in the tests), and is skipped unless the
#' `NOT_CRAN` environment variable is `"true"`.
#'
#' For more control, source the files yourself and use [with_coverage()].
#' @section Files from a package:
#' To make the package's other functions available, load the package (e.g.
#' with `pkgload::load_all()`) and use `parent_env = asNamespace("pkg")`.
#' Calls from other package files use the namespace's untraced functions, so
#' don't count. `devtools::test_coverage_active_file()` measures the coverage
#' of one file of a package without this limitation.
#' @section Compiled code:
#' [environment_coverage()] and [with_coverage()] include the compiled code in
#' the coverage of the namespace of a package loaded with `pkgload::load_all()`
#' (e.g. by `devtools::load_all()`), so `devtools::test_coverage_active_file()`
#' also works for files in `src/`. With compiled files in `source_files`,
#' `file_coverage()` loads their package with `pkgload::load_all()` and reports
#' the coverage of those files, without needing devtools:
#'
#' ```r
#' file_coverage("src/foo.c", "tests/testthat/test-foo.R")
#' ```
#'
#' The compiled code is measured with gcov in the current session, which is
#' much faster than [package_coverage()]. An instrumented copy of the package
#' is built in the session's temporary directory, leaving the package's own
#' build untouched, and later runs only recompile the files that changed.
#' While the code runs, the namespace's native routines use the instrumented
#' DLL instead of the package's own. Routines that were looked up some other
#' way, e.g. stored by `.onLoad()` or found by other packages with
#' `R_GetCCallable()`, keep using the package's DLL, so their code isn't
#' counted. Set `options(covr.gcov = "")` to leave out compiled code.
#' @return A [coverage] object.
#' @examples
#' # Save code and tests to temporary files
#' source_file <- tempfile(fileext = ".R")
#' test_file <- tempfile(fileext = ".R")
#' cat("add <- function(x, y) { x + y }", file = source_file)
#' cat("add(1, 2) == 3", file = test_file)
#'
#' # Use file_coverage() to calculate test coverage
#' file_coverage(source_files = source_file, test_files = test_file)
#' @export
file_coverage <- function(
  source_files,
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL,
  parent_env = parent.frame(),
  runner = source_test_file
) {
  compiled <- is_compiled_file(source_files)
  if (any(compiled)) {
    ns <- load_compiled_package(source_files[compiled])
    if (missing(parent_env)) {
      parent_env <- ns
    }
  }

  env <- new.env(parent = parent_env)

  withr::with_options(c("keep.parse.data.pkgs" = TRUE), {
    lapply(
      source_files[!compiled],
      sys.source,
      keep.source = TRUE,
      envir = env
    )
  })

  if (any(compiled)) {
    state <- start_compiled_coverage(ns, required = TRUE)
    on.exit(stop_compiled_coverage(state), add = TRUE)
  }

  trace_environment(env)
  on.exit(
    {
      reset_traces()
      clear_counters()
    },
    add = TRUE
  )

  coverage <- collect_coverage(
    lapply(test_files, runner, env = env)
  )

  if (any(compiled)) {
    coverage <- add_compiled_coverage(coverage, state)
    # Only keep the compiled files asked for
    is_compiled <- vlapply(coverage, inherits, "line_coverage")
    filenames <- vcapply(coverage, function(x) {
      get_source_filename(x$srcref, full.names = TRUE, normalize = TRUE)
    })
    coverage <- coverage[
      !is_compiled | filenames %in% normalize_path(source_files[compiled])
    ]
  }

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
}

source_test_file <- function(file, env) {
  sys.source(file, envir = env, keep.source = TRUE)
}

#' Calculate coverage of code directly
#'
#' This function is useful for testing, and is a thin wrapper around
#' [file_coverage()] because parseData is not populated properly
#' unless the functions are defined in a file.
#' @param source_code A character vector of source code
#' @param test_code A character vector of test code
#' @inheritParams file_coverage
#' @param ... Additional arguments passed to [file_coverage()]
#' @inheritSection file_coverage Parallel code
#' @return A [coverage] object.
#' @examples
#' source <- "add <- function(x, y) { x + y }"
#' test <- "add(1, 2) == 3"
#' code_coverage(source, test)
#' @export
code_coverage <- function(
  source_code,
  test_code,
  line_exclusions = NULL,
  function_exclusions = NULL,
  ...
) {
  src <- tempfile("source.R")
  test <- tempfile("test.R")
  on.exit(file.remove(src, test))
  cat(source_code, file = src)
  cat(test_code, file = test)
  file_coverage(
    src,
    test,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    ...
  )
}
