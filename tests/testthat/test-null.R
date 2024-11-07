test_that("coverage of functions with NULL constructs", {
  f1 <- function() NULL
  f2 <- function() {
    NULL
  }
  f3 <- function() {
    if (FALSE) {
      NULL
    }
  }
  f4 <- function() {
    if (FALSE)
      NULL
  }

  cv1 <- function_coverage(f1, f1())
  expect_equal(percent_coverage(cv1), 100)
  cv2 <- function_coverage(f2, f2())
  expect_equal(percent_coverage(cv2), 100)
  cv3 <- function_coverage(f3, f3())
  expect_equal(percent_coverage(cv3), 50)
  cv4 <- function_coverage(f4, f4())
  expect_equal(percent_coverage(cv4), 50)
})
