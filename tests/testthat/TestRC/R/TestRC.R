#' an example function
#'
#' @export
a <- function(x) {
  if (x <= 1) {
    1
  } else {
    2
  }
}

#' @export
TestRC <- setRefClass("TestRC", # nolint
  fields = list(name = "character", enabled = "logical"),
  methods = list(
    show = function(x) {
      1 + 3
    },
    print2 = function(x) {
      1 + 2
    }
  )
)
