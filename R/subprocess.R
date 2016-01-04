#' Run R commands in a R subprocess
#'
#' this function runs a R subprocess then given \code{code}, trying to
#' replicate as much of the calling environment as possible, then returning the
#' results to the calling environment.
#' @param code expression to call in the subprocess
#' @param calling_env the environment of the calling function.
#' @param global_env the global environment to load in the subprocess.
#' @param clean whether to clean the Rout files generated from the subprocess.
#' @param quiet whether to echo the R command run.
subprocess <- function(code, calling_env = parent.frame(),
                            global_env = .GlobalEnv, # nolint
                            quiet = F,
                            clean = TRUE) {
  tmp_calling_env <- tempfile()
  tmp_global_env <- tempfile()

  tmp_code <- tempfile()
  tmp_objs <- tempfile()

  saveRDS(substitute(code), file = tmp_code)

  saveRDS(calling_env, file = tmp_calling_env)

  save(list = ls(envir = global_env, all.names = TRUE),
       envir = global_env,
       file = tmp_global_env)

  tmp_source <- tempfile()

  command <- sprintf(
    paste(sep = "\n",
      "options(error = function() traceback(2))",
      "options(warn = 1)",
      "load('%s')",
      ".code <- readRDS('%s')",
      "fun <- function() {",
      "eval(.code)",
      "  .new_objs <- ls(environment())",
      "  if (length(.new_objs) > 0) {",
      "    save(list = .new_objs, file = '%s')",
      "  }",
      "  invisible(.new_objs)",
      "}",
      ".env <- readRDS('%s')",
      "environment(fun) <- .env",
      "fun()"),
    normalizePath(tmp_global_env, winslash = "/", mustWork = FALSE),
    normalizePath(tmp_code, winslash = "/", mustWork = FALSE),
    normalizePath(tmp_objs, winslash = "/", mustWork = FALSE),
    normalizePath(tmp_calling_env, winslash = "/", mustWork = FALSE)
  )

  writeChar(con = tmp_source, command, eos = NULL)

  with_options(c(show.error.messages = FALSE), {
    output <- R(options = c("-f", tmp_source, "--slave"),
      path = ".")
  })

  rout_file <- paste0(basename(tmp_source), ".Rout")
  if (clean) {
    if (file.exists(rout_file)) {
      unlink(rout_file)
    } else if (!quiet) {
        message(rout_file, " does not exist1")
    }
  }

  if (file.exists(tmp_objs)) {
    load(envir = calling_env, file = tmp_objs)
  } else if (!quiet) {
        message(tmp_objs, " does not exist2")
  }
}
