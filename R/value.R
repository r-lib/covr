#' Retrieve the execution counts from a coverage object
#'
#' @param x a coverage object, as returned by [package_coverage()], or one of
#'   its elements.
#' @param ... additional arguments passed to methods.
#' @return For a coverage object, a named numeric vector with the number of
#'   times each traced expression or line was executed, named like the
#'   elements of `x` (see the Value section of [package_coverage()]). For a
#'   single element, its count.
#' @examples
#' cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
#' value(cov)
#' @export
value <- function(x, ...) UseMethod("value")

#' @export
value.default <- function(x, ...) {
  x$value
}

#' @export
value.coverage <- function(x, ...) {
  vdapply(x, value, ...)
}
