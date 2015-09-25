context("no_try")
test_that("package coverage exits prematurely when `no_try=FALSE`", {
  expect_true(percent_coverage(package_coverage("TestNoTry")) < 50)
  expect_equal(percent_coverage(package_coverage("TestNoTry", no_try=TRUE)), 100)
})
