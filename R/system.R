#' Run a system command and check if it succeeds.
#'
#' This function automatically quotes both the command and each
#' argument so they are properly protected from shell expansion.
#' @param cmd the command to run.
#' @param args a vector of command arguments.
#' @param env a named character vector of environment variables.  Will be quoted
#' @param quiet if \code{TRUE}, the command output will be echoed.
#' @param echo if \code{TRUE}, the command to run will be echoed.
#' @param ... additional arguments passed to \code{\link[base]{system}}
#' @return \code{TRUE} if the command succeeds, an error will be thrown if the
#' command fails.
system_check <- function(cmd, args = character(), env = character(),
                         quiet = FALSE, echo = FALSE, ...) {
  full <- paste(c(shQuote(cmd), lapply(args, shQuote)), collapse = " ")

  if (echo) {
    message(wrap_command(full), "\n")
  }

  status <- withr::with_envvar(env,
    system(full, intern = FALSE, ignore.stderr = quiet, ignore.stdout = quiet, ...)
    )

  if (!identical(as.character(status), "0")) {
    stop("Command ", sQuote(full), " failed (", status, ")", call. = FALSE)
  }

  invisible(TRUE)
}

#' Run a system command and capture the output.
#'
#' This function automatically quotes both the command and each
#' argument so they are properly protected from shell expansion.
#' @inheritParams system_check
#' @return command output if the command succeeds, an error will be thrown if
#' the command fails.
system_output <- function(cmd, args = character(), env = character(),
                          quiet = FALSE, echo = FALSE, ...) {
  full <- paste(c(shQuote(cmd), lapply(args, shQuote)), collapse = " ")

  if (echo) {
    message(wrap_command(full), "\n")
  }
  result <- withCallingHandlers(withr::with_envvar(env,
    system(full, intern = TRUE, ignore.stderr = quiet, ...)
    ), warning = function(w) stop(w))

  result
}

wrap_command <- function(x) {
  lines <- strwrap(x, getOption("width") - 2, exdent = 2)
  continue <- c(rep(" \\", length(lines) - 1), "")
  paste(lines, continue, collapse = "\n")
}
