#' Run a system command and capture the output.
#'
#' This function automatically quotes both the command and each
#' argument so they are properly protected from shell expansion.
#' @param cmd the command to run.
#' @param args a vector of command arguments.
#' @param env a named character vector of environment variables.  Will be quoted
#' @param quiet if `TRUE`, the command's standard error is discarded.
#' @param ... additional arguments passed to [base::system()]
#' @return command output if the command succeeds, an error will be thrown if
#' the command fails.
#' @keywords internal
system_output <- function(
  cmd,
  args = character(),
  env = character(),
  quiet = FALSE,
  ...
) {
  full <- paste(c(shQuote(cmd), lapply(args, shQuote)), collapse = " ")

  # `system()` signals a failure as a warning. Check the status rather than
  # re-signalling the warning with `stop()`, which keeps its warning class so
  # `tryCatch(error = )` doesn't catch it.
  result <- suppressWarnings(withr::with_envvar(
    env,
    system(full, intern = TRUE, ignore.stderr = quiet, ...)
  ))
  status <- attr(result, "status")
  if (!is.null(status)) {
    stop("running command '", full, "' had status ", status, call. = FALSE)
  }

  result
}

wrap_command <- function(x) {
  lines <- strwrap(x, getOption("width") - 2, exdent = 2)
  continue <- c(rep(" \\", length(lines) - 1), "")
  paste(lines, continue, collapse = "\n")
}
