#context("Compiled")
#test_that("Compiled code coverage is reported", {
  #cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  #expect_equal(cov$first_line, c(3, 6, 7, 9, 11, 12, 14, 15, 16, 17, 18, 19, 20, 22, 24))

  #expect_equal(cov$value, c(4, 4, 4, 4, 4, 4, 4, 3, 3, 1, 0, 0, 1, 4, 4))
#})
