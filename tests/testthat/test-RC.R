context("RC")
test_that("RC methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestRC"))

  expect_equal(cov$value, c(5, 2, 3))
  expect_equal(cov$first_line, c(5, 6, 8))
  expect_equal(cov$last_line, c(5, 6, 8))
})
