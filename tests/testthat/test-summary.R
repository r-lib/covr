context("summary_functions")

test_that("Summary gives 50% coverage", {
  expect_equal(percent_coverage(package_coverage("TestSummary")), 0.5)
})

zero_Summary <- zero_coverage(package_coverage("TestSummary"))

test_that("Summary gives 1 lines with 0 coverage", {
  expect_equal(nrow(zero_Summary), 1)
})
