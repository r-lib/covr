context("package_coverage")
test_that("package_coverage returns NULL if the path does not exist", {
  expect_error(package_coverage("blah"))
})
