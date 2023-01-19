replacements_box <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
       if (inherits(obj, "box$mod")) {
         lapply(names(obj),
            function(f_name) {
              f <- get(f_name, obj)
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
