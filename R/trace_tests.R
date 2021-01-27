#' Record Test Traces During Coverage Execution
#'
#' By setting `options(covr.record_tests = TRUE)`, the result of covr coverage
#' collection functions will include additional data pertaining to the tests
#' which are executed and an index of which tests, at what stack depth, trigger
#' the execution of each trace.
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
#' @param key generated with [key()]
#' @keywords internal
#'
update_current_test <- function(key) {
  syscalls <- sys.calls()
  syscall_srcref_dirs <- lapply(syscalls, getSrcDirectory)
  syscall_first_count <- Position(is_covr_count_call, syscalls)

  # find frames with relative srcref; ie src within /tests directory
  has_srcdir <- vapply(syscall_srcref_dirs, length, integer(1L)) > 0L
  test_frames <- logical(length(syscall_srcref_dirs))
  test_frames[has_srcdir] <- startsWith(as.character(syscall_srcref_dirs[has_srcdir]), ".")
  test_frames <- which(test_frames)

  # add in outer frame, which may call intermediate .Internal or .External
  exec_frames <- unique(c(test_frames, syscall_first_count - 1L))

  # build data for current test and append to .counters$tests
  .current_test$trace <- syscalls[exec_frames]
  .current_test$frame <- tail(exec_frames, 1L)
  .current_test$srcref <- getSrcref(syscalls[[.current_test$frame]])

  # build test data to store within .counters
  test <- list(.current_test$trace)
  names(test) <- file.path(getSrcDirectory(.current_test$srcref), key(.current_test$srcref))

  .counters$tests <- append(.counters$tests, test)
}

#' Returns TRUE if we've moved on from test reflected in .current_test
#'
is_current_test_finished <- function() {
  syscalls <- sys.calls()

  is.null(.current_test$trace) ||
  .current_test$frame > length(syscalls) ||
  !identical(.current_test$srcref, getSrcref(syscalls[[.current_test$frame]]))
}

is_covr_count_call <- function(expr) {
  expr[[1]] == quote(covr:::count)
}
