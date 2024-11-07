#' @import S7
Range <- new_class("Range",
  properties = list(
    start = class_double,
    end = class_double,
    length = new_property(
      class = class_double,
      getter = function(self) self@end - self@start,
      setter = function(self, value) {
        self@end <- self@start + value
        self
      }
    )
  ),
  constructor = function(x) {
    new_object(S7_object(), start = as.double(min(x, na.rm = TRUE)), end = as.double(max(x, na.rm = TRUE)))
  },
  validator = function(self) {
    if (length(self@start) != 1) {
      "@start must be length 1"
    } else if (length(self@end) != 1) {
      "@end must be length 1"
    } else if (self@end < self@start) {
      "@end must be greater than or equal to @start"
    }
  }
)

#' @export
inside <- new_generic("inside", "x")

method(inside, Range) <- function(x, y) {
  y >= x@start & y <= x@end
}
