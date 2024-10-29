test_that("range works", {
  x <- range(1:10)

  x@end <- 20

  expect_error(x@end <- "x", "must be <double>")

  expect_error(x@end <- -1, "greater than or equal")

  expect_equal(inside(x, c(0, 5, 10, 15)), c(FALSE, TRUE, TRUE, TRUE))

  x@length <- 5

  expect_equal(x@length, 5)
  expect_equal(x@end, 6)
})


