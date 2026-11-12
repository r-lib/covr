replacement <- function(
  name,
  env = as.environment(-1),
  target_value = get(name, envir = env)
) {
  if (is.function(target_value) && !is.primitive(target_value)) {
    # The wrappers of vectorized and memoised functions are not traced, only
    # the functions they call. These are replaced in place, like any other
    # function, so `reset()` restores them.
    inner <- wrapped_function(target_value)
    if (!is.null(inner)) {
      return(replacement(name, env = environment(target_value), inner))
    }

    # Tracing an instrumented function again would replace its counts with
    # counters for the instrumentation itself (#641).
    if (is_traced(target_value)) {
      return(NULL)
    }

    # The `.Call` the counters call, for `trace_calls()`
    old_dot_call <- the$dot_call
    the$dot_call <- dot_call(environment(target_value))
    on.exit(the$dot_call <- old_dot_call)

    new_value <- trace_calls(target_value, name)
    attributes(body(new_value)) <- attributes(body(target_value))
    attributes(new_value) <- attributes(target_value)

    if (isS4(target_value)) {
      new_value <- asS4(new_value)
    }

    list(
      env = env,
      name = as.name(name),
      orig_value = .Call(covr_duplicate_, target_value),
      target_value = target_value,
      new_value = new_value
    )
  }
}

# The function that the wrapper `x` of a vectorized or memoised function calls,
# or `NULL` if `x` is not such a wrapper.
wrapped_function <- function(x) {
  name <- if (is_vectorized(x)) {
    "FUN"
  } else if (inherits(x, "memoised")) {
    "_f"
  }
  if (!is.null(name)) {
    get0(name, environment(x), mode = "function", inherits = FALSE)
  }
}

replace <- function(replacement) {
  .Call(covr_reassign_function, replacement$target_value, replacement$new_value)
}

reset <- function(replacement) {
  .Call(
    covr_reassign_function,
    replacement$target_value,
    replacement$orig_value
  )
}
