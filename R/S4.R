replacements_S4 <- function(env) {
  generics <- getGenerics(env)

  unlist(recursive = FALSE,
    Map(generics@.Data, generics@package, USE.NAMES = FALSE,
      f = function(name, package) {
      what <- methodsPackageMetaName("T", paste(name, package, sep = ":"))

      table <- get(what, envir = env)

      lapply(ls(table, all.names = TRUE), replacement, env = table)
    })
  )
}
