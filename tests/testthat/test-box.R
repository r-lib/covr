test_that("box module coverage is reported", {
  cov <- box_coverage("Testbox")

  expect_equal(cov$value, c(5, 2, 3, 3))
  expect_equal(cov$first_line, c(5, 6, 8, 13))
  expect_equal(cov$last_line, c(5, 6, 8, 13))
  expect_contains(cov$functions, c("a", "private_function"))
})

test_that("box attached module coverage is reported", {
  cov <- box_coverage("Testbox_attached_modules_functions")

  expect_equal(cov$value, c(20, 8, 12, 3, 0))
  expect_equal(cov$first_line, c(5, 6, 8, 14, 18))
  expect_equal(cov$last_line, c(5, 6, 8, 14, 18))
  expect_contains(cov$functions, c("a", "private_function"))
})

test_that("R6 box module coverage is reported", {
  # Similar to test-R6.R, there is some sort of bug that causes this test
  # to fail during R CMD check in R-devel, not sure why, and can't reproduce
  # it interactively
  skip_if(is_r_devel())
  cov <- box_coverage("Testbox_R6")

  expect_equal(cov$value, c(1, 1))
  expect_equal(cov$first_line, c(5, 8))
  expect_equal(cov$last_line, c(5, 8))
  expect_contains(cov$functions, "show")
})

test_that("R6 box attached module coverage is reported", {
  # Similar to test-R6.R, there is some sort of bug that causes this test
  # to fail during R CMD check in R-devel, not sure why, and can't reproduce
  # it interactively
  skip_if(is_r_devel())
  cov <- box_coverage("Testbox_attached_modules_functions_R6")

  expect_equal(cov$value, c(1, 1))
  expect_equal(cov$first_line, c(5, 8))
  expect_equal(cov$last_line, c(5, 8))
  expect_contains(cov$functions, "show")
})
