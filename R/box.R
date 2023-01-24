replacements_box_modules <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
        if (inherits(attr(obj, "spec"), "box$mod_spec")) {
         obj_impl <- attr(obj, "namespace")
         lapply(ls(obj_impl),
            function(f_name) {
              f <- get(f_name, obj_impl)
              if (inherits(f, "function")) {
                replacement(f_name, env = obj, target_value = f)
              }
              # This else if looks like it should work, but it doesn't
              # else if (inherits(f, "R6ClassGenerator")) {
              #   traverse_R6(f, obj)
              # }
            }
          )
        }
      }
    )
  )
}

replacements_box_r6 <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
        if (inherits(attr(obj, "spec"), "box$mod_spec")) {
          obj_impl <- attr(obj, "namespace")
          unlist(recursive = FALSE, lapply(ls(obj_impl),
              function(f_name) {
                f <- get(f_name, obj_impl)
                if (inherits(f, "R6ClassGenerator")) {
                  traverse_R6(f, obj)
                }
                # keeping this here for notes
                # if (inherits(f, "R6ClassGenerator")) {
                #   unlist(recursive = FALSE, eapply(f, all.names = TRUE,
                #       function(o) {
                #         if (inherits(o, "list")) {
                #           lapply(names(o),
                #             function(m_name) {
                #               m <- get(m_name, o)
                #               if (inherits(m, "function")) {
                #                 replacement(m_name, env = obj, target_value = m)
                #               }
                #             }
                #           )
                #         }
                #       }
                #     )
                #   )
                # }
              }
            )
          )
        }
      }
    )
  )
}

replacements_box <- function(env) {
  c(
    replacements_box_modules(env),
    replacements_box_r6(env)
  )
}
