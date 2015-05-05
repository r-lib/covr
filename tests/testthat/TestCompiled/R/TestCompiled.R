#' an example function
#'
#' @useDynLib TestCompiled simple_
simple <- function(x) {
  .Call(simple_, x) # nolint
}
