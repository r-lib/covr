test_that("S4 methods coverage is reported", {
  cov <- as.data.frame(package_coverage("TestS4"))

  expect_equal(cov$first_line, c(7, 8, 10, 25, 31, 37))

  expect_equal(cov$value, c(5, 2, 3, 1, 1, 1))
})
