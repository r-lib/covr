#' Retrieve the display name from an object
#' @export
#' @param x object from which to retrieve the display name
#' @param ... additional arguments passed to methods
#' @export
display_name <- function(x, ...) vapply(x, function(xx) getSrcFilename(xx$srcref), character(1))

#' @export
display_name.default <- function(x, ...) {
  src_ref <- attr(x, "srcref")
  if (!is.null(src_ref)) {
    display_name(src_ref)
  } else {
    names(x)
  }
}

#' @export
display_name.srcref <- function(x, ...) {
  attr(x, "srcfile")$display_name
}

#' @export
display_name.srcfile <- function(x, ...) {
  x$display_name
}

#' @export
display_name.expression_coverage <- function(x, ...) {
  display_name.srcref(x$srcref, ...)
}

#' @export
display_name.line_coverage <- function(x, ...) {
  display_name.srcfile(x$file, ...)
}

#' @export
display_name.coverage <- function(x, ...) {
  vapply(x, display_name, character(1), ..., USE.NAMES = FALSE)
}

#' @export
display_name.expression_coverages <- display_name.coverage

#' @export
display_name.line_coverages <- display_name.coverage

#' Set the display name for an object
#' @export
#' @param x object to set the display name
#' @param value what to set the display name to
#' @export
#' @export
"display_name<-" <- function(x, value) UseMethod("display_name<-")

"display_name<-.default" <- function(x, value) {
  names(x) <- value
  x
}

#' @export
"display_name<-.srcref" <- function(x, value) {
  attr(x, "srcfile")$display_name <- value
  x
}

#' @export
"display_name<-.expression_coverage" <- function(x, value) {
  display_name(x$srcref) <- value
  x
}

#' @export
"display_name<-.srcfile" <- function(x, value) {
  x$display_name <- value
  x
}
