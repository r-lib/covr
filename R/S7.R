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
  # Each binding in the environment at x@methods is either a function or, for
  # generics that dispatch on multiple arguments, another environment.
  get_replacements <- function(env) {
    replacements <- lapply(names(env), function(name) {
      target_value <- get(name, envir = env)
      if (is.environment(target_value)) {
        # Recurse for nested environments
        get_replacements(target_value)
      } else {
        list(replacement(name, env, target_value))
      }
    })
    unlist(replacements, FALSE, FALSE)
  }
  get_replacements(x@methods)
}

traverse_S7_class <- function(x) {
  prop_fun_replacements <-
    lapply(x@properties, function(p) {
      lapply(c("getter", "setter", "validator"), function(prop_fun) {
        if (!is.null(p[[prop_fun]])) {
          replacement(prop_fun, env = p, target_value = p[[prop_fun]])
        }
      })
  })
  prop_fun_replacements <- unlist(prop_fun_replacements, FALSE, FALSE)

  c(
    list(
      replacement("constructor", env = x, target_value=x@constructor),
      replacement("validator", env = x, target_value=x@validator)
    ),
    prop_fun_replacements
  )
}