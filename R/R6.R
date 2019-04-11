replacements_R6 <- function(env) {
  unlist(recursive = FALSE, eapply(env, all.names = TRUE,
    function(obj) {
      if (inherits(obj, "R6ClassGenerator")) {
        unlist(recursive = FALSE, eapply(obj,
          function(o) {
            if (inherits(o, "list")) {
              lapply(names(o),
                  function(f_name) {
                  f <- get(f_name, o)
                  if (inherits(f, "function")) {
                    replacement(f_name, env = env, target_value = f)
                  }
})
      }
    }))
}
    }))
}
