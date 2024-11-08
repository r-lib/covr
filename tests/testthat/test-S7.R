test_that("S7 coverage is reported", {
  cov <- as.data.frame(package_coverage(test_path("TestS7")))

  expect_equal(cov$value, c(1, 1, 1, 1, 4, 0, 4, 0, 4, 1, 1))
})
