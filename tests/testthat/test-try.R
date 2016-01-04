context("use_try")
test_that("package coverage exits prematurely when `use_try=FALSE`", {
  expect_true(percent_coverage(package_coverage("TestUseTry", use_try = TRUE)) < 50)
  expect_equal(percent_coverage(package_coverage("TestUseTry", use_try = FALSE)), 100)
})
