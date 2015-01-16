#' Run R commands in a R subprocess
#'
#' this function runs a R subprocess with expressions given in ..., trying to
#' replicate as much of the calling environment as possible, then returning the
#' results to the calling environment.
#' @param ... expressions to call in the subprocess
#' @param calling_env the environment of the calling function.
#' @param global_env the global environment to load in the subprocess.
#' @param clean_output whether to clean the Rout files generated from the subprocess.
#' @param quiet whether to echo the R command run.
subprocess <- function(..., calling_env = parent.frame(),
                            global_env = .GlobalEnv,
                            quiet = TRUE,
                            clean_output = TRUE) {
  exprs <- eval(substitute(alist(...)))

  tmp_calling_env <- tempfile()
  tmp_global_env <- tempfile()

  tmp_exprs <- tempfile()
  tmp_output <- tempfile()

  saveRDS(exprs, file = tmp_exprs)

  saveRDS(calling_env, file = tmp_calling_env)
  save(list=ls(envir = global_env, all.names = TRUE), envir = global_env, file = tmp_global_env)

  tmp_source <- tempfile()

  command <- sprintf("
library(methods)
load('%s')
.exprs <- readRDS('%s')
fun <- function() {
  for(.expr in .exprs) {
    eval(.expr)
  }
  .new_objs <- ls(environment())
  if (length(.new_objs) > 0) {
    save(list = .new_objs, file = '%s')
  }
  .new_objs
}
.env <- readRDS('%s')
environment(fun) <- .env
fun()",
tmp_global_env, tmp_exprs, tmp_output, tmp_calling_env)

  writeChar(con = tmp_source, command, eos = NULL)
  output <- try(devtools:::RCMD("BATCH",
                                c("--slave", tmp_source),
                                path = ".",
                                quiet = TRUE),
                              silent = quiet)

  if (inherits(output, "try-error")) {
    lines <- readLines(paste0(basename(tmp_source), ".Rout"))
    lapply(lines, message)
    stop("Subprocess failed")
  }

  rout_file <- paste0(basename(tmp_source), ".Rout")
  if (clean_output) {
    if (file.exists(rout_file)) {
      unlink(rout_file)
    } else if (!quiet) {
        message(rout_file, " does not exist")
    }
  }

  if (file.exists(tmp_output)) {
    load(envir = calling_env, file = tmp_output)
  } else if (!quiet) {
        message(tmp_output, " does not exist")
  }
}
