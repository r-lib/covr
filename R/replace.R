#' @useDynLib covr, .registration = TRUE
replacement <- function(
  name,
  env = as.environment(-1),
  target_value = get(name, envir = env)
) {
  if (is.function(target_value) && !is.primitive(target_value)) {
    # The wrappers of vectorized and memoised functions are not traced, only
    # the functions they call.
    inner <- if (is_vectorized(target_value)) {
      "FUN"
    } else if (inherits(target_value, "memoised")) {
      "_f"
    }
    traced <- if (is.null(inner)) {
      target_value
    } else {
      environment(target_value)[[inner]]
    }
    # Tracing an instrumented function again would replace its counts with
    # counters for the instrumentation itself (#641).
    if (is_traced(traced)) {
      return(NULL)
    }

    # The `.Call` the counters call, for `trace_calls()`
    old_dot_call <- the$dot_call
    the$dot_call <- dot_call(environment(traced))
    on.exit(the$dot_call <- old_dot_call)

    if (is.null(inner)) {
      new_value <- trace_calls(target_value, name)
      attributes(body(new_value)) <- attributes(body(target_value))
    } else {
      new_value <- target_value
      environment(new_value)[[inner]] <- trace_calls(traced, name)
    }
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
