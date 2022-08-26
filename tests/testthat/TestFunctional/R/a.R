foo <- function(x) {
  force(x)
  function() {
    if (x < 1)
    {
      return(TRUE)
    } else {
      return(FALSE)
    }
  }
}

#' @export
a <- foo(0)

#' @export
b <- foo(1)
