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
TestR6 <- R6::R6Class("TestR6", # nolint
  public = list(
    show = function(x) {
      1 + 3
    },
    print2 = function(x) {
      1 + 2
    }
  )
)

.InternalTestR6 <- R6::R6Class("InternalTestR6", # nolint
    public = list(
        some_method = function(x){
            1 + 2
        }
    )
)
