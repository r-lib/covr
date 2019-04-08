context("R6")

test_that("R6 methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestR6"))

  expect_equal(cov$value, c(5, 2, 3, 1, 1, 0))
  expect_equal(cov$first_line, c(5, 6, 8, 16, 19, 27))
  expect_equal(cov$last_line, c(5, 6, 8, 16, 19, 27))
  expect_true("some_method" %in% cov$functions)
})
