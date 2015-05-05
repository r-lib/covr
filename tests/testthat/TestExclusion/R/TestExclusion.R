#' an example function
#'
#' @export
test_me <- function(x, y){
  x + y
}

# nocov start
#' @export
dont_test_me <- function(x, y){
  x * y
}
# nocov end

#' @export
test_exclusion <- function(x) {
  if (x > 5) {
    1 # nocov
  } else {
    2
  }
}
