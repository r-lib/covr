context("S4")
test_that("S4 methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestS4"))

  expect_equal(cov$first_line, c(3, 20, 26, 32))

  expect_equal(cov$value, c(5, 1, 1, 1))
})
