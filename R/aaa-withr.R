with_envvar <- function(envvars, expr) {
  old <- `names<-`(lapply(names(envvars), Sys.getenv), names(envvars))
  on.exit(do.call(Sys.setenv, old))
  do.call(Sys.setenv, as.list(envvars))
  force(expr)
}

withr <- list2env(list(
  with_envvar      = with_envvar,
  with_dir         = with_dir,
  with_makevars    = with_makevars,
  with_output_sink = with_output_sink,
  with_options     = with_options
))
