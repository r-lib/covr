fun_list <- list(
  a = function(x) {
    x + 1
  },
  b = function(x) {
    x + 2
  }
)

api <- local({
  helper <- function() {
    1
  }
  function() helper()
})
