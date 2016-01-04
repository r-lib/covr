#' an example function
#'
#' @export
#' @examples
#' a(1)
a <- function(x) {
  if (x <= 1) {
    1
  } else {
    2
  }
}

#' @export
TestS4 <- setClass("TestS4", # nolint
  slots = list(name = "character", enabled = "logical"))

#' @export
setGeneric("print2", function(x, y) {
})

setMethod("print2",
  c(x = "TestS4"),
  function(x) {
    1 + 1
  })

setMethod("print2",
  c(x = "TestS4", y = "character"),
  function(x, y) {
    1 + 2
  })

setMethod("show",
  c(object = "TestS4"),
  function(object) {
    1 + 3
  })
