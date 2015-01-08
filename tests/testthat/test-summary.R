context("summary_functions")

test_that("S4 gives 100% coverage", {
  expect_equal(1, percent_coverage(package_coverage("TestS4")))
})

zero_S4 <- zero_coverage(package_coverage("TestS4"))

test_that("S4 gives 0 lines with 0 coverage", {
  expect_equal(0, nrow(zero_S4))
})
