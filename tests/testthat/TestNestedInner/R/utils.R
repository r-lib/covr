inner_fun <- function(x) {
  x <- x + 2
  outer_fun(x)
}
