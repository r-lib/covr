#' @export

fun <- function() {
  withCallingHandlers(
    signalCondition(simpleError("This Will Exit if `no_try==FALSE`")),
    error=function(e) TRUE
  )
  1 + 1
  2 + 2
  "hello"
  "welcome"
  TRUE
}
