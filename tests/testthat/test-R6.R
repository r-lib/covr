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

test_that("active bindings are not read when looking for R6 classes", {
  skip_if_not_installed("R6")
  # R6 coverage is wrong during R CMD check on R-devel, see above
  skip_if(is_r_devel())
  src <- paste(
    "makeActiveBinding('ab', function() stop('boom'), environment())",
    "Gen <- R6::R6Class('Gen', public = list(f = function() {",
    "  1",
    "}))",
    sep = "\n"
  )
  cov <- as.data.frame(code_coverage(src, "Gen$new()$f()"))
  expect_equal(cov$value, 1)
})
