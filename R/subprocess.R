# this function calls a subprocess with expressions given in ..., trying to
# replicate as much of the calling environment as possible, then returning the
# results to the calling environment.
subprocess <- function(..., env = parent.frame()) {
  exprs <- eval(substitute(alist(...)))

  calling_env <- environment(sys.function(sys.parent()))

  tmp_env <- tempfile()

  tmp_read <- tempfile()

  tmp_exprs <- tempfile()

  tmp_output <- tempfile()

  tmp_namespaces <- tempfile()

  saveRDS(exprs, file = tmp_exprs)

  saveRDS(calling_env, file = tmp_env)

  namespaces <- lapply(loadedNamespaces(), getNamespace)

  saveRDS(namespaces, file = tmp_namespaces)

  save(list=ls(env), envir = env, file = tmp_read)

  tmp_source <- tempfile()

  command <- sprintf("
library(methods)
.vars <- load('%s')
.ns <- readRDS('%s')
for (namespace in .ns) {
  try(suppressPackageStartupMessages(attachNamespace(namespace)), silent = TRUE)
}
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
tmp_read, tmp_namespaces, tmp_exprs, tmp_output, tmp_env)

  writeChar(con = tmp_source, command, eos = NULL)
  devtools:::RCMD("BATCH", paste0(tmp_source, " --vanilla"), path = ".")

  if (file.exists(tmp_output)) {
    load(envir = env, file = tmp_output)
  } else {
    message(tmp_output, " does not exist")
  }
}
