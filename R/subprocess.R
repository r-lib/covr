# this function calls a subprocess with expressions given in ..., trying to
# replicate as much of the calling environment as possible, then returning the
# results to the calling environment.
subprocess <- function(..., calling_env = parent.frame(),
                            function_env = environment(sys.function(sys.parent())),
                            global_env = .GlobalEnv,
                            clean_output = FALSE) {
  exprs <- eval(substitute(alist(...)))

  function_env <- environment(sys.function(sys.parent()))

  tmp_calling_env <- tempfile()
  tmp_function_env <- tempfile()
  tmp_global_env <- tempfile()

  tmp_exprs <- tempfile()
  tmp_output <- tempfile()

  saveRDS(exprs, file = tmp_exprs)

  saveRDS(calling_env, file = tmp_calling_env)

  saveRDS(function_env, file = tmp_function_env)

  save(list=ls(envir = global_env, all.names = TRUE), envir = global_env, file = tmp_global_env)

  tmp_source <- tempfile()

  command <- sprintf("
library(methods)
load('%s')
.exprs <- readRDS('%s')
fun <- function() {
  for(expr in .exprs) {
    eval(expr)
  }
  .new_objs <- ls(environment())
  if (length(.new_objs) > 0) {
    save(list = .new_objs, file = '%s')
  }
}
.env <- readRDS('%s')
environment(fun) <- .env
fun()",
tmp_global_env, tmp_exprs, tmp_output, tmp_calling_env)

  writeChar(con = tmp_source, command, eos = NULL)
  try(devtools:::RCMD("BATCH", tmp_source, path = "."))

  rout_file <- paste0(basename(tmp_source), ".Rout")
  if (clean_output) {
    if (file.exists(rout_file)) {
      unlink(rout_file)
    } else {
      message(rout_file, " does not exist")
    }
  }

  if (file.exists(tmp_output)) {
    load(envir = calling_env, file = tmp_output)
  } else {
    message(tmp_output, " does not exist")
  }
}
