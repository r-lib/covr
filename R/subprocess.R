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
                            global_env = .GlobalEnv, # nolint
                            quiet = TRUE,
                            clean_output = TRUE) {
  exprs <- eval(substitute(alist(...)))

  tmp_calling_env <- tempfile()
  tmp_global_env <- tempfile()

  tmp_exprs <- tempfile()
  tmp_objs <- tempfile()

  saveRDS(exprs, file = tmp_exprs)

  saveRDS(calling_env, file = tmp_calling_env)

  save(list=ls(envir = global_env, all.names = TRUE),
       envir = global_env,
       file = tmp_global_env)

  tmp_source <- tempfile()

  command <- sprintf(
    paste(sep = "\n",
      "load('%s')",
      ".exprs <- readRDS('%s')",
      "fun <- function() {",
      "    for(.expr in .exprs) {",
      "      eval(.expr)",
      "    }",
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
    normalizePath(tmp_exprs, winslash = "/", mustWork = FALSE),
    normalizePath(tmp_objs, winslash = "/", mustWork = FALSE),
    normalizePath(tmp_calling_env, winslash = "/", mustWork = FALSE)
  )

  writeChar(con = tmp_source, command, eos = NULL)
  output <- try(devtools:::R(options=paste("-f", tmp_source,
                                           "--slave",
                                           collapse = " "),
                             path = "."))

  if (inherits(output, "try-error")) {
    #lines <- readLines(paste0(basename(tmp_source), ".Rout"))
    #cat(lines, sep="\n")
    stop("Subprocess failed!", call. = FALSE)
  }

  rout_file <- paste0(basename(tmp_source), ".Rout")
  if (clean_output) {
    if (file.exists(rout_file)) {
      unlink(rout_file)
    } else if (!quiet) {
        message(rout_file, " does not exist")
    }
  }

  if (file.exists(tmp_objs)) {
    load(envir = calling_env, file = tmp_objs)
  } else if (!quiet) {
        message(tmp_objs, " does not exist")
  }
}
