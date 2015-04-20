value <- function(x, ...) UseMethod("value")

value.coverage <- function(x, ...) {
  vapply(x, value, numeric(1), ...)
}

value.expression_coverage <- function(x, ...) {
  x$value
}

value.expression_coverages <- value.coverage
value.line_coverage <- value.expression_coverage
value.line_coverages <- value.expression_coverages
