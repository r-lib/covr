context("Compiled")
test_that("Compiled code coverage is reported", {
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  expect_equal(cov$first_line, c(3, 20, 26, 32))

  expect_equal(cov$value, c(5, 1, 1, 1))
})
