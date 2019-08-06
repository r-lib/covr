#' an example function
#'
#' @useDynLib TestCompiled simple_
simple <- function(x) {
  .Call(simple_, x) # nolint
}

simple3 <- function(x) {
  .Call(simple3_, x) # nolint
}

simple4 <- function(x) {
  .Call(simple4_, x) # nolint
}
