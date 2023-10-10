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
