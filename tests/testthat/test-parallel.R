context("coverage of parallel code")


test_that("mcparallel", {
  cov <- package_coverage("TestParallel", type = "test")
  expect_true(percent_coverage(cov) > 0)
})
