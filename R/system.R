# Runs `cmd` with the arguments `args` and the environment variables `env`
# (a named character vector), without a shell, so they need no quoting.
# Returns its exit `status` and its standard output and error as `stdout` and
# `stderr`, in lines. A command that can't be started has status 127 and the
# reason as its standard error. A nonzero status isn't an error, so callers
# choose how to handle it.
run_command <- function(cmd, args = character(), env = character()) {
  res <- tryCatch(
    withr::with_envvar(
      env,
      sys::exec_internal(cmd, args, error = FALSE)
    ),
    error = function(e) {
      list(
        status = 127L,
        stdout = raw(),
        stderr = charToRaw(conditionMessage(e))
      )
    }
  )
  list(
    status = res$status,
    stdout = raw_to_lines(res$stdout),
    stderr = raw_to_lines(res$stderr)
  )
}

raw_to_lines <- function(x) {
  text <- rawToChar(x[x != 0L])
  if (!nzchar(text)) {
    return(character())
  }
  strsplit(text, "\r?\n")[[1]]
}

# The command as it is shown to the user, with quoted arguments.
command_line <- function(cmd, args = character()) {
  paste(c(shQuote(cmd), lapply(args, shQuote)), collapse = " ")
}

# Runs a command and returns its output, quoting the command and each argument
# so they are protected from shell expansion. `env` is a named character
# vector of environment variables to set. The command's standard error is shown
# unless `quiet`. Signals an error if the command fails.
system_output <- function(
  cmd,
  args = character(),
  env = character(),
  quiet = FALSE
) {
  res <- run_command(cmd, args, env)
  if (!quiet && length(res$stderr)) {
    message(paste(res$stderr, collapse = "\n"))
  }
  if (res$status != 0L) {
    stop(
      "running command '",
      command_line(cmd, args),
      "' had status ",
      res$status,
      call. = FALSE
    )
  }
  res$stdout
}

wrap_command <- function(x) {
  lines <- strwrap(x, getOption("width") - 2, exdent = 2)
  continue <- c(rep(" \\", length(lines) - 1), "")
  paste(lines, continue, collapse = "\n")
}
