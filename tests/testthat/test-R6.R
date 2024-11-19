test_that("R6 methods coverage is reported", {
  # There is some sort of bug that causes this test to fail during R CMD check
  # in R-devel, not sure why, and can't reproduce it interactively
  skip_if(is_r_devel())
  cov <- as.data.frame(package_coverage(test_path("TestR6")))

  expect_equal(cov$value, c(5, 2, 3, 1, 1, 0))
  expect_equal(cov$first_line, c(5, 6, 8, 16, 19, 27))
  expect_equal(cov$last_line, c(5, 6, 8, 16, 19, 27))
  expect_true("some_method" %in% cov$functions)
})
