#' an example function
#'
#' @useDynLib TestCompiledSubdir simple_
simple <- function(x) {
  .Call(simple_, x) # nolint
}
