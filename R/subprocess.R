subprocess <- function(..., env = parent.frame()) {

  exprs <- eval(substitute(alist(...)))


  tmp_read <- tempfile()

  tmp_exprs <- tempfile()

  tmp_write <- tempfile()

  saveRDS(exprs, file = tmp_exprs)

  original_variables <- ls(env)

  save(list=original_variables, envir = env, file = tmp_read)
  system2("Rscript", shQuote(
      c("-e", "library(methods);",
        "-e", sprintf("load('%s')", tmp_read),
        "-e", sprintf(".exprs <- readRDS('%s')", tmp_exprs),
        "-e", "for(expr in .exprs) eval(expr)",
        "-e", sprintf("save(list = setdiff(ls(), %s), file = '%s')",
          paste0("c(", paste0("'", original_variables, "'", collapse = ","), ")"),
          tmp_write))))

  load(envir = env, file = tmp_write)
}
