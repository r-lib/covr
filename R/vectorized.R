# Whether `x` is a function made by `Vectorize()`: its own environment, not an
# enclosing one, has the bindings that the function uses, which it reads in its
# body.
is_vectorized <- function(x) {
  if (!is.function(x) || is.primitive(x)) {
    return(FALSE)
  }
  env <- environment(x)
  used <- c("FUN", "vectorize.args", "SIMPLIFY", "USE.NAMES")
  is.environment(env) &&
    all(used %in% all.names(body(x))) &&
    all(vlapply(used, has_inactive_binding, env = env)) &&
    is.function(env[["FUN"]])
}

has_inactive_binding <- function(name, env) {
  exists(name, envir = env, inherits = FALSE) && !bindingIsActive(name, env)
}
