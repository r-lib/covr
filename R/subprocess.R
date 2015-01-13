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

  system2("Rscript", shQuote(
      c("-e", "library(methods);",
        "-e", sprintf(".vars <- load('%s')", tmp_read),
        "-e", sprintf(".ns <- readRDS('%s');for (namespace in .ns) try(suppressPackageStartupMessages(attachNamespace(namespace)), silent = TRUE)", tmp_namespaces),
        "-e", sprintf(".exprs <- readRDS('%s');fun <- function() { for(expr in .exprs) eval(expr); .new_objs <- ls(environment()); if (length(.new_objs) > 0) save(list = .new_objs, file = '%s') }", tmp_exprs, tmp_output),
        "-e", sprintf(".env <- readRDS('%s');environment(fun) <- .env;fun()", tmp_env)
      )), env = c("R_TESTS" = "", "NOT_CRAN" = "true"))

  if (file.exists(tmp_output)) {
    load(envir = env, file = tmp_output)
  }
}
