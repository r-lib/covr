display_name <- function(x, ...) UseMethod("display_name")

display_name.srcref <- function(x, ...) {
  attr(x, "srcfile")$display_name
}

display_name.srcfile <- function(x, ...) {
  x$display_name
}

display_name.coverage <- function(x, ...) {
  vapply(x, display_name, character(1), ..., USE.NAMES = FALSE)
}

display_name.expression_coverage <- function(x, ...) {
  display_name(x$srcref, ...)
}
display_name.expression_coverages <- display_name.coverage

display_name.line_coverage <- function(x, ...) {
  display_name(x$file, ...)
}
display_name.line_coverages <- display_name.coverage


"display_name<-" <- function(x, value, ...) UseMethod("display_name<-")

"display_name<-.srcref" <- function(x, value, ...) {
  attr(x, "srcfile")$display_name <- value
}

"display_name<-.srcfile" <- function(x, value, ...) {
  x$display_name <- value
}
