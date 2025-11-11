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
#'     `$tests` field is now included which contains a matrix with three columns,
#'     "test", "call", "depth" and "i" which specify the test number
#'     (corresponding to the index of the test in `attr(,"tests")`, the number
#'     of times the test expression was evaluated to produce the trace hit, the
#'     stack depth into the target code where the trace was executed, and the
#'     order of execution for each test.
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
#'     f(!x)
#'   else
#'     FALSE
#' }'
#'
#' options(covr.record_tests = TRUE)
#' cov <- code_coverage(fcode, "f(TRUE)")
#'
#' # extract executed test code for the first test
#' tail(attr(cov, "tests")[[1L]], 1L)
#' # [[1]]
#' # f(TRUE)
#'
#' # extract test itemization per trace
#' cov[[3]][c("srcref", "tests")]
#' # $srcref
#' # f(!x)
#' #
#' # $tests
#' #      test call depth i
#' # [1,]    1    1     2 4
#'
#' # reconstruct the code path of a test by ordering test traces by [,"i"]
#' lapply(cov, `[[`, "tests")
#' # $`source.Ref2326138c55:4:6:4:10:6:10:4:4`
#' #      test call depth i
#' # [1,]    1    1     1 2
#' #
#' # $`source.Ref2326138c55:3:8:3:8:8:8:3:3`
#' #      test call depth i
#' # [1,]    1    1     1 1
#' # [2,]    1    1     2 3
#' #
#' # $`source.Ref2326138c55:6:6:6:10:6:10:6:6`
#' #      test call depth i
#' # [1,]    1    1     2 4
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

  if (is_current_test_finished()) {
    update_current_test()
  }

  # ignore if .counter was not created with record_tests (nested coverage calls)
  if (is.null(.counters[[key]]$tests)) return()

  .current_test$i <- .current_test$i + 1L

  # expand infrequently as new tests are added, doubling matrix size as needed
  tests <- .counters[[key]]$tests
  n <- NROW(tests$tally)
  if (.counters[[key]]$value > n) {
    tests$tally <- rbind(tests$tally, matrix(NA_integer_, ncol = 4L, nrow = n))
  }

  # ignore if .current_test was not initialized properly yet
  if (length(.current_test$index) == 0) {
    return()
  }

  # test number
  tests$.data[[1L]] <- .current_test$index

  # test call number (for test expressions that are called multiple times)
  tests$.data[[2L]] <- .current_test$call_count

  # call stack depth when trace is hit
  tests$.data[[3L]] <- sys.nframe() - length(.current_test$frames) - n_calls_into_covr + 1L

  # number of traces hit by the test so far
  tests$.data[[4L]] <- .current_test$i

  tests$.value <- .counters[[key]]$value
  with(tests, tally[.value, ] <- .data)
}

#' Initialize a new test counter for a coverage trace
#'
#' Initialize a test counter, a matrix used to tally tests, their stack depth
#' and the execution order as the trace associated with \code{key} is hit. Each
#' test trace is an environment, which allows assignment into a pre-allocated
#' \code{tests} matrix with minimall reallocation.
#'
#' The \code{tests} matrix has columns \code{tests}, \code{depth} and \code{i},
#' corresponding to the test index (the index of the associated test in
#' \code{.counters$tests}), the stack depth when the trace is evaluated and the
#' number of traces that have been hit so far during test evaluation.
#'
#' @inheritParams count
#'
new_test_counter <- function(key) {
  .counters[[key]]$tests <- new.env(parent = baseenv())
  .counters[[key]]$tests$.data <- vector("integer", 4L)
  .counters[[key]]$tests$.value <- integer(1L)
  .counters[[key]]$tests$tally <- matrix(
    NA_integer_,
    ncol = 4L,
    # initialize with 4 empty rows, only expanded once populated
    nrow = 4L,
    # cols: test index; call index; call stack depth of covr:::count; execution order index
    dimnames = list(c(), c("test", "call", "depth", "i"))
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
#' checks to see if the current call stack has the same
#' `srcref` (or expression, if no source is available) at the same frame prior
#' to entering into a package where `covr:::count` is called.
#'
#' @keywords internal
#'
#' @importFrom utils getSrcDirectory
#'
update_current_test <- function() {
  syscalls <- sys.calls()
  syscall_first_count <- Position(is_covr_count_call, syscalls, nomatch = -1L)
  if (syscall_first_count < 2L) return()  # skip if nothing before covr::count
  syscall_srcfile <- vcapply(syscalls, get_source_filename, normalize = TRUE)

  has_srcfile <- viapply(syscall_srcfile, length) > 0L
  srcfile_tmp <- logical(length(has_srcfile))
  srcfile_tmp[has_srcfile] <- startsWith(
    syscall_srcfile[has_srcfile],
    normalizePath(.libPaths()[[1]], mustWork = FALSE)
  )

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
  .current_test$i <- 0L
  .current_test$frames <- exec_frames
  .current_test$last_frame <- exec_frames[[Position(
    has_srcref,
    .current_test$trace,
    right = TRUE,
    nomatch = length(exec_frames)
  )]]

  # might be NULL if srcrefs aren't kept during building / sourcing
  .current_test$src_env <- sys.frame(which = .current_test$last_frame - 1L)
  .current_test$src_call <- syscalls[[.current_test$last_frame]]
  .current_test$srcref <- getSrcref(.current_test$src_call)
  .current_test$src <- .current_test$srcref %||% .current_test$src_call

  .current_test$key <- current_test_key()
  .current_test$index <- current_test_index()
  .current_test$call_count <- current_test_call_count()

  # NOTE: r-bugs 18348
  # restrict test call lengths to avoid R Rds deserialization limit
  # https://bugs.r-project.org/show_bug.cgi?id=18348
  max_call_len <- 1e4
  call_lengths <- vapply(.current_test$trace, length, numeric(1L))
  if (any(call_lengths > max_call_len)) {
    .current_test$trace <- lapply(
      .current_test$trace,
      truncate_call,
      limit = max_call_len
    )

    warning("A large call was captured as part of a test and will be truncated.")
  }

  .counters$tests[[.current_test$index]] <- .current_test$trace
  attr(.counters$tests[[.current_test$index]], "call_count") <- .current_test$call_count
  names(.counters$tests)[[.current_test$index]] <- .current_test$key
}

#' Build key for the current test
#'
#' If the current test has a srcref, a unique character key is built from its
#' srcref. Otherwise, an empty string is returned.
#'
#' @return A unique character string if the test call has a srcref, or an empty
#'   string otherwise.
#'
#' @keywords internal
current_test_key <- function() {
  if (!inherits(.current_test$src, "srcref")) return("")
  file.path(
    dirname(get_source_filename(.current_test$src, normalize = TRUE)),
    key(.current_test$src)
  )
}

#' Retrieve the index for the test in `.counters$tests`
#'
#' If the test was encountered before, the index will be the index of the test
#' in the logged tests list. Otherwise, the index will be the next index beyond
#' the length of the tests list.
#'
#' @return An integer index for the test call
#'
#' @keywords internal
current_test_index <- function() {
  # check if test has already been encountered and reuse test index
  if (inherits(.current_test$src, "srcref")) {
    # when tests have srcrefs, we can quickly compare test keys
    match(
      .current_test$key,
      names(.counters$tests),
      nomatch = length(.counters$tests) + 1L
    )
  } else {
    # otherwise we compare call stacks
    Position(
      function(t) identical(t[], .current_test$trace),  # t[] to ignore attr
      .counters$tests,
      right = TRUE,
      nomatch = length(.counters$tests) + 1L
    )
  }
}

#' Retrieve the number of times the test call was called
#'
#' A single test expression might be evaluated many times. Each time the same
#' expression is called, the call count is incremented.
#'
#' @return An integer value representing the number of calls of the current
#'   call into the package from the testing suite.
#'
current_test_call_count <- function() {
  if (.current_test$index <= length(.counters$tests)) {
    attr(.counters$tests[[.current_test$index]], "call_count") + 1L
  } else {
    1L
  }
}

#' Truncate call objects to limit the number of arguments
#'
#' A helper to circumvent R errors when deserializing large call objects from
#' Rds. Trims the number of arguments in a call object, and replaces the last
#' argument with a `<truncated>` symbol.
#'
#' @param call_obj A (possibly large) \code{call} object
#' @param limit A \code{call} length limit to impose
#' @return The \code{call_obj} with arguments trimmed
#'
truncate_call <- function(call_obj, limit = 1e4) {
  if (length(call_obj) < limit) return(call_obj)
  call_obj <- head(call_obj, limit)
  call_obj[[length(call_obj)]] <- quote(`<truncated>`)
  call_obj
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
  is.null(.current_test$src) ||
    .current_test$last_frame > sys.nframe() ||
    !identical(.current_test$src_call, sys.call(which = .current_test$last_frame)) ||
    !identical(.current_test$src_env, sys.frame(which = .current_test$last_frame - 1L))
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
