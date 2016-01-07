context("package_coverage")
test_that("package_coverage returns an error if the path does not exist", {
  expect_error(package_coverage("blah"))
})

test_that("package_coverage returns an error if the type is incorrect", {
  expect_error(package_coverage("TestPrint", type = "blah"),
    "'arg' should be one of")

  expect_error(package_coverage("TestPrint", type = c("blah", "test")),
    "'arg' should be one of")
})

test_that("package_coverage can return just tests and vignettes", {
  cov <- package_coverage("TestPrint", type = c("test", "vignette"))

  expect_equal(names(cov), c("test", "vignette"))
})

test_that("package_coverage with type == 'all' returns test, vignette and example coverage", {
  cov <- package_coverage("TestPrint", type = "all")

  expect_equal(names(cov), c("test", "vignette", "example"))
})

test_that("package_coverage with type == 'none' runs no test code", {
  cov <- package_coverage("TestS4", type = "none")

  expect_equal(percent_coverage(cov), 0.00)
})
