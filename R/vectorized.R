# simple function to test if a function is Vectorized
is_vectorized <- function(x) {
  is.function(x) && exists("FUN", environment(x))
}
