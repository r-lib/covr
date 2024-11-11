replacements_S7 <- function(env) {
  bindings <- unlist(recursive = FALSE, use.names = FALSE, eapply(env, all.names = TRUE,
    function(obj) {
      if (inherits(obj, "S7_generic")) {
        traverse_S7_generic(obj)
      } else if (inherits(obj, "S7_class")) {
        traverse_S7_class(obj)
      }
    }))

  S7_methods_tbl <- attr(env[[".__S3MethodsTable__."]], "S7methods", exact = TRUE)
  external_methods <- lapply(seq_along(S7_methods_tbl), function(i) {
    entry <- S7_methods_tbl[[i]]
    name <- external_generic_method_signature(entry$generic, entry$signature)

    replacement(
      # `name` is for informative printouts only.
      # It is not used by covr, and does not need to be unique,
      name = name,
      env = entry,
      target_value = entry$method)
  })

  c(bindings, external_methods)
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
        name <- as.character(attr(target_value, "name", exact = TRUE) %||% name)
        list(replacement(name, env, target_value))
      }
    })
    unlist(replacements, recursive = FALSE, use.names = FALSE)
  }
  get_replacements(S7::prop(x, "methods"))
}

traverse_S7_class <- function(x) {
  class_name <- S7::prop(x, "name")
  prop_fun_replacements <-
    lapply(S7::prop(x, "properties"), function(p) {
      lapply(c("getter", "setter", "validator"), function(prop_fun) {
        if (!is.null(p[[prop_fun]])) {
          replacement(
            sprintf("%s@properties$%s$%s", class_name, p$name, prop_fun),
            env = p,
            target_value = p[[prop_fun]])
        }
      })
  })
  prop_fun_replacements <- unlist(prop_fun_replacements, recursive = FALSE, use.names = FALSE)

  c(
    list(
      replacement(paste0(class_name, "@constructor"), env = x, target_value = S7::prop(x, "constructor")),
      replacement(paste0(class_name, "@validator")  , env = x, target_value = S7::prop(x, "validator"))
    ),
    prop_fun_replacements
  )
}


external_generic_method_signature <- function(generic, signature) {
  # This function is a lightly modified copy of S7:::method_signature() for external generics
  display_generic <- paste0(c(generic$package, generic$name), collapse = "::")
  class_deparse <- asNamespace("S7")$class_deparse # not exported from S7 :/
  single <- length(generic$dispatch_args) == 1
  if (single) {
    signature <- class_deparse(signature[[1]])
  } else {
    classes <- vapply(signature, class_deparse, "", USE.NAMES = FALSE)
    signature <- paste0("list(", paste0(classes, collapse = ", "), ")")
  }

  sprintf("method(%s, %s)", display_generic, signature)
}
