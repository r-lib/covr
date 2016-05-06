replacements_RC <- function(env) {
  pat <- paste0("^", classMetaName(""))
  unlist(recursive = FALSE, lapply(ls(env, pattern = pat, all.names = TRUE),
    function(name) {
      class <- get(name, env)
      if (extends(class, "envRefClass")) {
       lapply(ls(class@refMethods, all.names = TRUE), replacement, env = class@refMethods)
      }
    }))
}
