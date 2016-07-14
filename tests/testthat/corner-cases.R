make_fun_1 <- function() {
  function(x) {
    2 + 2
    1 + 1
    cat("fun1\n")
  }
}
make_fun_2 <- function() {
  function(x) {
    3 + 3
    4 + 4
    cat("fun2\n")
  }
}
#' @export

fun1 <- make_fun_1()

#' @export

fun2 <- function(x) {
  2 + 2
  1 + 1
  cat("fun2\n")
}
#' @export

fun3 <- function() {

  if(FALSE)
    1
  else
    2

1 +
1; if(TRUE) 1 else 2

  if(FALSE) 3 else 4
  if(FALSE) {3} else {4}

  if(TRUE) 3 else {1 + 1
    2 + 2
  }
  {1 + 1; 2 + 2}; if(FALSE) 1 else 2; {TRUE}
  {1 + 1; 2 + 2}; "hello"; {TRUE}
  if(TRUE) {
    {1 + 1; 2 + 2}; "hello"; {TRUE}
    {1 + 1; 2 + 2}; if(FALSE) 1 else 2; {TRUE}
  } else {
    {1 + 1; 2 + 2}; "hello"; {TRUE}
    {1 + 1; 2 + 2}; if(FALSE) 1 else 2; {TRUE}
  }
}
#' @export

setGeneric("fun4", function(x) StandardGeneric("fun2"))

setMethod("fun4", "integer", make_fun_2())
setMethod("fun4", "numeric", make_fun_1())
