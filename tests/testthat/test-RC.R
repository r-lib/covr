context("RC")
test_that("RC methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestRC"))

  expect_equal(cov$value, 5)
  expect_equal(cov$first_line, 3)
  expect_equal(cov$last_line, 7)
})
