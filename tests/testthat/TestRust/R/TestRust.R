rust_sign <- function(x) {
  .Call(sign_wrapper, x)
}
