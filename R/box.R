replacements_box <- function(env) {
  unlist(
    recursive = FALSE,
    eapply_inactive(env, function(obj) {
      if (inherits(attr(obj, "spec"), "box$mod_spec")) {
        obj_impl <- attr(obj, "namespace")
        # Each binding of the module is read once, and is either a function or
        # an R6 generator.
        compact(unlist(
          recursive = FALSE,
          lapply(ls(obj_impl), function(f_name) {
            f <- get(f_name, obj_impl)
            if (inherits(f, "function")) {
              list(replacement(f_name, env = obj, target_value = f))
            } else if (inherits(f, "R6ClassGenerator")) {
              traverse_R6(f, obj)
            }
          })
        ))
      }
    })
  )
}
