#' Retrieve the value from an object
#' @export
#' @param x object from which to retrieve the value
#' @param ... additional arguments passed to methods
value <- function(x, ...) UseMethod("value")

#' @export
value.coverage <- function(x, ...) {
  vapply(x, value, numeric(1), ...)
}

#' @export
value.expression_coverage <- function(x, ...) {
  x$value
}

#' @export
value.expression_coverages <- value.coverage

#' @export
value.line_coverage <- value.expression_coverage

#' @export
value.line_coverages <- value.expression_coverages
