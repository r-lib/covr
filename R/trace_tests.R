#' Record Test Traces During Coverage Execution
#'
#' By setting `options(covr.record_tests = TRUE)`, the result of covr coverage
#' collection functions will include additional data pertaining to the tests
#' which are executed and an index of which tests, at what stack depth, trigger
#' the execution of each trace.
#'
#' This functionality requires that the package code and tests are installed and
#' sourced with the source. For more details, refer to R options, `keep.source`,
#' `keep.source.pkgs` and `keep.parse.data.pkgs`.
#'
#' @section Additional fields:
#'
#' Within the `covr` result, you can explore this information in two places:
#'
#' \itemize{
#'   \item `attr(,"tests")`: A list of call stacks, which results in target code
#'     execution.
#'
#'   \item `$<srcref>$tests`: For each srcref count in the coverage object, a
#'     `$tests` field is now included which contains a matrix with two columns,
#'     "test" and "depth" which specify the test number (corresponding to the
#'     index of the test in `attr(,"tests")` and the stack depth into the target
#'     code where the trace was executed.
#' }
#'
#' @section Test traces:
#'
#' The content of test traces are dependent on the unit testing framework that
#' is used by the target package. The behavior is contingent on the available
#' information in the sources kept for the testing files.
#'
#' Test traces are extracted by the following criteria:
#'
#' 1. If any `srcref` files are are provided by a file within [covr]'s temporary
#'    library, all calls from those files are kept as a test trace. This will
#'    collect traces from tests run with common testing frameworks such as
#'    `testthat` and `RUnit`.
#' 1. Otherwise, as a conservative fallback in situations where no source
#'    references are found, or when none are from within the temporary
#'    directory, the entire call stack is collected.
#'
#' These calls are subsequently subset for only those up until the call to
#' [covr]'s internal `count` function, and will always include the last call in
#' the call stack prior to a call to `count`. 
#'
#' @examples
#' fcode <- '
#' f <- function(x) {
#'   if (x)
#'     TRUE
#'   else
#'     FALSE
#' }'
#'
#' options(covr.record_tests = TRUE)
#' cov <- code_coverage(fcode, "f(TRUE)")
#'
#' # extract executed tests traces
#' attr(cov, "tests")
#' # $`/tmp/test.R:1:1:1:7:1:7:1:1`
#' # $`/tmp/test.R:1:1:1:7:1:7:1:1`[[1]]
#' # f(TRUE)
#'
#' # extract test itemization per trace
#' cov[[3]][c("srcref", "tests")]
#' # $srcref
#' # TRUE
#' #
#' # $tests
#' #      test depth
#' # [1,]    1     1
#'
#' @name covr.record_tests
NULL

#' Append a test trace to a counter, updating global current test
#'
#' @param key generated with [key()]
#' @keywords internal
#'
count_test <- function(key) {
  n_calls_into_covr <- 2L

  if (is_current_test_finished())
    update_current_test(key)

  depth_into_pkg <- length(sys.calls()) - .current_test$frame - n_calls_into_covr + 1L
  .counters[[key]]$tests <- rbind(
    .counters[[key]]$tests,
    c(length(.counters$tests), depth_into_pkg)
  )
}

#' Update current test if unit test expression has progressed
#'
#' Updating a test logs some metadata regarding the current call stack, noteably
#' trying to capture information about the call stack prior to the covr::count
#' call being traced. 
#'
#' There are a couple patterns of behavior, which try to accommodate a variety
#' of testing suites:
#'
#' \itemize{
#'   \item `testthat`: During execution of `testthat`'s `test_*` functions,
#'     files are sourced and the working directory is temporarily changed to the
#'     package `/tests` directory. Knowing this, calls in the call stack which
#'     are relative to this directory are extracted and recorded. 
#'   \item `RUnit`: 
#'   \item `custom`: Any other custom test suites may not have source kept with
#'     their execution, in which case the entire test call stack is kept. 
#' }
#'
#'
#' checks to see if the current call stack has the same
#' `srcref` (or expression, if no source is available) at the same frame prior 
#' to entering into a package where `covr:::count` is called. 
#'
#' @param key generated with [key()]
#' @keywords internal
#'
#' @importFrom utils getSrcDirectory
#'
update_current_test <- function(key) {
  syscalls <- sys.calls()
  syscall_srcfile <- vcapply(syscalls, get_source_filename, normalize = TRUE)
  syscall_first_count <- Position(is_covr_count_call, syscalls)

  has_srcfile <- viapply(syscall_srcfile, length) > 0L
  srcfile_tmp <- logical(length(has_srcfile))
  srcfile_tmp[has_srcfile] <- startsWith(syscall_srcfile[has_srcfile], normalizePath(.libPaths()[[1]]))

  test_frames <- if (any(srcfile_tmp)) {
    # if possible, try to take any frames within the temporary library
    which(srcfile_tmp)
  } else {
    # otherwise, default to taking all syscalls up until covr:::count
    seq_len(syscall_first_count - 1L)
  }

  # add in outer frame, which may call intermediate .Internal or .External
  exec_frames <- unique(c(test_frames, syscall_first_count - 1L))

  # build updated current test data, isolating relevant frames
  .current_test$trace <- syscalls[exec_frames]
  .current_test$frames <- exec_frames
  .current_test$last_frame <- exec_frames[[Position(
    has_srcref, 
    .current_test$trace, 
    right = TRUE, 
    nomatch = length(exec_frames))]]

  # might be NULL if srcrefs aren't kept during building / sourcing
  .current_test$src <- getSrcref(syscalls[[.current_test$last_frame]]) %||% 
    syscalls[[.current_test$last_frame]]

  # build test data to store within .counters
  test <- list(.current_test$trace)

  # only name if srcrefs can be determined
  if (inherits(.current_test$src, "srcref")) {
    names(test) <- file.path(
      dirname(get_source_filename(.current_test$src, normalize = TRUE)),
      key(.current_test$src))
  }

  .counters$tests <- append(.counters$tests, test)
}

#' Returns TRUE if we've moved on from test reflected in .current_test
#'
#' Quickly dismiss the need to update the current test if we can. To test if
#' we're still in the last test, check if the same srcref (or call, if source is
#' not kept) exists at the last recorded calling frame prior to entering a covr
#' trace. If this has changed, do a more comprehensive test to see if any of the
#' test call stack has changed, in which case we are onto a new test. 
#'
is_current_test_finished <- function() {
  syscalls <- sys.calls()

  is.null(.current_test$src) ||
  .current_test$last_frame > length(syscalls) ||
  !identical(
    .current_test$src, 
    getSrcref(syscalls[[.current_test$last_frame]]) %||% syscalls[[.current_test$last_frame]]
  ) ||
  !identical(
    .current_test$trace,
    syscalls[.current_test$frames]
  )
}

#' Is the source bound to the expression
#'
#' @param expr A language object which may have a `srcref` attribute
#' @return A logical value indicating whether the language object has source
#'
has_srcref <- function(expr) {
  !is.null(getSrcref(expr))
}

#' Is the expression a call to covr:::count
#'
#' @param expr A language object
#' @return A logical value indicating whether the object is a call to
#'   `covr:::count`.
#' 
is_covr_count_call <- function(expr) {
  count_call <- call(":::", as.symbol("covr"), as.symbol("count"))
  identical(expr[[1]], count_call)
}
