replacements_box <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
        if (inherits(attr(obj, "spec"), "box$mod_spec")) {
          obj_impl <- attr(obj, "namespace")
          compact(c(
            lapply(ls(obj_impl),
              function(f_name) {
                f <- get(f_name, obj_impl)
                if (inherits(f, "function")) {
                  replacement(f_name, env = obj, target_value = f)
                }
              }
            ),
            unlist(recursive = FALSE,
              lapply(ls(obj_impl),
                function(f_name) {
                  f <- get(f_name, obj_impl)
                  if (inherits(f, "R6ClassGenerator")) {
                    traverse_R6(f, obj)
                  }
                }
              )
            )
          ))
        }
      }
    )
  )
}
