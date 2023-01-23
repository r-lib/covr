replacements_box <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
       if (inherits(obj, "box$mod")) {
         obj_impl <- attr(obj, "namespace")
         lapply(ls(obj_impl),
            function(f_name) {
              f <- get(f_name, obj_impl)
              if (inherits(f, "function")) {
                replacement(f_name, env = obj, target_value = f)
              }
            }
          )
        }
      }
    )
  )
}
