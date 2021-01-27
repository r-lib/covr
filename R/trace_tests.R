#' Append a test trace to a counter, updating global current test 
#'
#' @param key generated with [key()]
#' @keywords internal
#'
count_test <- function(key) {
  n_calls_into_covr <- 2L

  if (is_current_test_finished()) 
    update_current_test(key)

  depth_into_pkg <- length(sys.calls()) - .current_test$frame - n_calls_into_covr
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
  .current_test$frame <- if (length(test_frames)) {
    # use test directory source code if available
    tail(test_frames, 1L)  
  } else { 
    # otherwise use outer frame (ie for `code_coverage`)
    tail(exec_frames, 1L)  #
  }
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
