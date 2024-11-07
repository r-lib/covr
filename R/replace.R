#' @useDynLib covr, .registration = TRUE
replacement <- function(name, env = as.environment(-1), target_value = get(name, envir = env)) {
  if (is.function(target_value) && !is.primitive(target_value)) {
    if (is_vectorized(target_value)) {
      new_value <- target_value
      environment(new_value)$FUN <- trace_calls(environment(new_value)$FUN, name)
    } else if (is.function(target_value) && inherits(target_value, "memoised")) {
      new_value <- target_value
      environment(new_value)$`_f` <- trace_calls(environment(new_value)$`_f`, name)
    } else {
      new_value <- trace_calls(target_value, name)
      attributes(body(new_value)) <- attributes(body(target_value))
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
  .Call(covr_reassign_function, replacement$target_value, replacement$orig_value)
}
