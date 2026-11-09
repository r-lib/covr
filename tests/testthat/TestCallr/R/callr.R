add_in_subprocess <- function(x, y) {
  callr::r(
    function(x, y) {
      x + y
    },
    list(x, y)
  )
}

never_called <- function() {
  1
}
