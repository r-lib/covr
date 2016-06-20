#' an example function
#'
#' @export
test_me <- function(x, y){
  if (TRUE)
    x + y
  else
    x - y
}

#' @export
dont_test_me <- function(x, y){
  x * y
}
