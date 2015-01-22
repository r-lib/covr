#' @export
test_me <- function(x, y){
  x + y
}

# EXCLUDE COVERAGE START
#' @export
dont_test_me <- function(x, y){
  x * y
}
# EXCLUDE COVERAGE END

#' @export
test_exclusion <- function(x) {
  if (x > 5) {
    1 # EXCLUDE COVERAGE
  } else {
    2
  }
}
