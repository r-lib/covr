test_that("Range works", {
  x <- Range(1:10)

  x@end <- 20

  expect_error(x@end <- "x", "must be <double>")

  expect_error(x@end <- -1, "greater than or equal")

  expect_equal(inside(x, c(0, 5, 10, 15)), c(FALSE, TRUE, TRUE, TRUE))

  x@length <- 5

  expect_equal(x@length, 5)
  expect_equal(x@end, 6)
})

test_that("Range methods work", {
  x <- Range(1:10)
  expect_equal(base::format(x), "Range(1, 10)")

  # Test external generic method for testthat::testthat_print()
  expect_equal(testthat::capture_output(x, print = TRUE), "Range(1, 10)")
})
