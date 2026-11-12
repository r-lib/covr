# Evaluate `code` and return the coverage it produced from the current traces.
# Unless disabled (see should_enable_parallel_mcexit_fix()), this includes code
# run in processes forked by parallel's mclapply(), mcparallel() etc.
collect_coverage <- function(code) {
  if (!should_enable_parallel_mcexit_fix()) {
    withr::with_envvar(c("R_COVR" = "true"), code)
    sync_counts()
    return(as_coverage(.counters))
  }

  trace_dir <- tempfile("covr_traces_")
  dir.create(trace_dir)
  restore_forks <- trace_forks(trace_dir)
  on.exit({
    restore_forks()
    unlink(trace_dir, recursive = TRUE)
  })

  withr::with_envvar(c("R_COVR" = "true"), code)

  sync_counts()
  counters <- as.list(.counters)
  as_coverage(merge_traces(trace_dir, counters))
}

#' Calculate coverage of an environment
#'
#' The functions in `env` are instrumented, then the files in `test_files` are
#' run with [sys.source()] in a child environment of `env`, from the current
#' working directory. Nothing else is set up, so testthat tests that rely on
#' its test runner, e.g. for setup files, snapshots, or the test directory as
#' the working directory (which [testthat::test_path()] uses to find fixtures
#' while testing), should instead be run with [testthat::test_file()] inside
#' [with_coverage()].
#'
#' @param env The environment to be instrumented.
#' @inheritParams file_coverage
#' @inheritSection file_coverage Parallel code
#' @inheritSection file_coverage Compiled code
#' @return A [coverage] object.
#' @seealso [with_coverage()]
#' @export
environment_coverage <- function(
  env = parent.frame(),
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  exec_env <- new.env(parent = env)

  with_coverage(
    lapply(test_files, sys.source, keep.source = TRUE, envir = exec_env),
    env = env,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions
  )
}

#' Calculate coverage of arbitrary code run against an environment
#'
#' `with_coverage()` instruments the functions in `env`, evaluates `code`, and
#' returns the coverage that `code` produced. Unlike [environment_coverage()],
#' which `sys.source()`s a set of files, `code` can be any expression. This
#' makes it possible to measure coverage while running tests with a test runner
#' such as [testthat::test_file()], without having to recreate the runner's
#' infrastructure (reporters, snapshot handling, test environment, ...).
#'
#' Functions are instrumented in place, so every existing reference to them,
#' including ones captured by an environment created by `code` (e.g. the child
#' environment of the namespace that [testthat::test_file()] evaluates tests
#' in), runs the instrumented version. The only requirement is that `code` must
#' not re-create the functions in `env`, e.g. when using
#' [testthat::test_file()] with `package` set the package must not be reloaded
#' (use `load_package = "none"`), as reloading would replace the instrumented
#' functions with fresh, uninstrumented ones.
#'
#' The instrumentation is removed and the counters are cleared when
#' `with_coverage()` exits, even if `code` fails.
#'
#' @param code The code to evaluate while measuring coverage. It is evaluated
#'   lazily, in the calling environment, after `env` has been instrumented.
#' @param env The environment to be instrumented, e.g. a package namespace.
#' @inheritParams file_coverage
#' @inheritSection file_coverage Parallel code
#' @inheritSection file_coverage Compiled code
#' @return A `coverage` object.
#' @seealso [environment_coverage()]
#' @examples
#' \dontrun{
#' # With a package loaded by pkgload::load_all()
#' ns <- asNamespace("mypkg")
#' with_coverage(
#'   testthat::test_file(
#'     "tests/testthat/test-foo.R",
#'     package = "mypkg",
#'     load_package = "none"
#'   ),
#'   env = ns
#' )
#' }
#' @export
with_coverage <- function(
  code,
  env = parent.frame(),
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  force(env)

  compiled <- start_compiled_coverage(env)
  on.exit(stop_compiled_coverage(compiled), add = TRUE)

  trace_environment(env)
  on.exit(
    {
      reset_traces()
      clear_counters()
    },
    add = TRUE
  )

  coverage <- collect_coverage(code)
  coverage <- add_compiled_coverage(coverage, compiled)

  exclude(
    coverage,
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions,
    path = NULL
  )
}
