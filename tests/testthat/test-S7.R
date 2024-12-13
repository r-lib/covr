test_that("S7 coverage is reported", {
  skip_if_not_installed("S7")
  cov <- as.data.frame(package_coverage(test_path("TestS7")))

  expect_equal(cov$value, c(1, 1, 1, 2, 5, 0, 5, 0, 5, 1, 1, 2, 1, 1, 0))
  expect_snapshot(cov[, c("functions", "first_line", "last_line", "value")])
})
