#' an example function
#'
#' @useDynLib TestCompiled simple_
simple <- function(x) {
  .Call(simple_, x) # nolint
}

simple2 <- function(x) {
  .Call(simple2_, x) # nolint
}
