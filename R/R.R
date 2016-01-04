#' Run R xxx from within R
#'
#' @param options a character vector of options to pass to the command
#' @param path the directory to run the command in.
#' @param env_vars environment variables to set before running the command.
#' @param ... additional arguments passed to \code{\link{system_check}}
R <- function(options, path = tempdir(), env_vars = NULL, ...) {
  options <- c("--vanilla", options)
  r_path <- file.path(R.home("bin"), "R")

  # If rtools has been detected, add it to the path only when running R...
  # This only needts to be done on windows

  if (.Platform$OS.type == "windows") {
    path <- (get("get_rtools_path", envir = asNamespace("devtools")))()
    if (!is.null(path)) {
      withr::with_path(path,
        withr::with_dir(path, system_check(r_path, options, c(r_env_vars(), env_vars), ...)))
    }
  }

  withr::with_dir(path, system_check(r_path, options, c(r_env_vars(), env_vars), ...))
}

#' Run R CMD xxx from within R
#'
#' @param cmd one of the R tools available from the R CMD interface.
#' @return \code{TRUE} if the command succeeds, throws an error if the command
#' fails.
#' @inheritParams R
RCMD <- function(cmd, options, path = tempdir(), env_vars = NULL, ...) {
  R(c("CMD", cmd, options), path = path, env_vars = env_vars, ...)
}

#' Environment variables to set when calling R
#'
#' Devtools sets a number of environmental variables to ensure consistent
#' between the current R session and the new session, and to ensure that
#' everything behaves the same across systems. It also suppresses a common
#' warning on windows, and sets \code{NOT_CRAN} so you can tell that your
#' code is not running on CRAN. If \code{NOT_CRAN} has been set externally, it
#' is not overwritten.
#'
#' @keywords internal
#' @return a named character vector
r_env_vars <- function() {
  vars <- c("R_LIBS" = paste(.libPaths(), collapse = .Platform$path.sep), # nolint
    "CYGWIN" = "nodosfilewarning",
    # When R CMD check runs tests, it sets R_TESTS. When the tests
    # themselves run R CMD xxxx, as is the case with the tests in
    # devtools, having R_TESTS set causes errors because it confuses
    # the R subprocesses. Un-setting it here avoids those problems.
    "R_TESTS" = "")

  if(is.na(Sys.getenv("NOT_CRAN", unset = NA))) {
    c(vars, "NOT_CRAN" = "true")
  } else {
    vars
  }
}
