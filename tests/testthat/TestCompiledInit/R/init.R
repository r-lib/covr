.loaded <- NULL

sign_of <- function(x) {
  .Call(C_sign_of, x)
}
