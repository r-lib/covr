replacements_S7 <- function(env) {
  unlist(recursive = FALSE, use.names = FALSE, eapply(env, all.names = TRUE,
    function(obj) {
      if (inherits(obj, "S7_generic")) {
        traverse_S7_generic(obj)
      } else if (inherits(obj, "S7_class")) {
        traverse_S7_class(obj)
      }
    }))
}

traverse_S7_generic <- function(x) {
	 lapply(names(x@methods), replacement, env = x@methods)
}

traverse_S7_class <- function(x) {
  c(use.names=FALSE,
    list(
      replacement("constructor", env = x, target_value=x@constructor),
      replacement("validator", env = x, target_value=x@validator)
    ),
    for (prop_fun in c("getter", "setter", "validator")) {
      lapply(x@properties, function(p) {
        if (!is.null(p[[prop_fun]])) { replacement(prop_fun, env=p, target_value=p[[prop_fun]]) }
      })
    }
  )
}