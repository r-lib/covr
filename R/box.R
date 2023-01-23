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

replacements_box_r6 <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
      function(obj) {
        if (inherits(obj, "box$mod")) {
          obj_impl <- attr(obj, "namespace")
          unlist(recursive = FALSE, lapply(ls(obj_impl),
              function(f_name) {
                f <- get(f_name, obj_impl)
                if (inherits(f, "R6ClassGenerator")) {
                  unlist(recursive = FALSE, eapply(f, all.names = TRUE,
                      function(o) {
                        if (inherits(o, "list")) {
                          lapply(names(o),
                            function(m_name) {
                              m <- get(m_name, o)
                              if (inherits(m, "function")) {
                                replacement(m_name, env = obj, target_value = m)
                              }
                            }
                          )
                        }
                      }
                    )
                  )
                }
              }
            )
          )
        }
      }
    )
  )
}
