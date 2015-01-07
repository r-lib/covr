context("R6")

test_that("R6 methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestR6"))

  expect_equal(cov$value, 5)
  expect_equal(cov$first_line, 3)
  expect_equal(cov$last_line, 7)
})

