replacements_S4 <- function(env) {
  generics <- getGenerics(env)

  unlist(
    recursive = FALSE,
    Map(
      generics@.Data,
      generics@package,
      USE.NAMES = FALSE,
      f = function(name, package) {
        what <- methodsPackageMetaName("T", paste(name, package, sep = ":"))

        table <- get(what, envir = env)

        lapply(ls(table, all.names = TRUE), function(key) {
          method <- get(key, envir = table)
          replacement(
            S4_method_name(name, key, method),
            env = table,
            target_value = method
          )
        })
      }
    )
  )
}

# Methods are named like their Rd aliases, e.g. `show,MyClass-method`, rather
# than by their keys in the methods table, e.g. `MyClass`, which don't include
# the generic (#417).
S4_method_name <- function(generic, key, method) {
  signature <- if (is(method, "MethodDefinition")) {
    as.character(method@defined)
  } else {
    strsplit(key, "#", fixed = TRUE)[[1]]
  }
  paste0(generic, ",", paste(signature, collapse = ","), "-method")
}
