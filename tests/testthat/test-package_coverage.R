test_that("package_coverage returns an error if the path does not exist", {
  expect_error(package_coverage("blah"))
})

test_that("package_coverage returns an error if the type is incorrect", {
  expect_error(
    package_coverage("TestPrint", type = "blah"),
    "'arg' should be one of")

  expect_error(package_coverage("TestPrint", type = c("blah", "test")),
    "'arg' should be one of")
})

test_that("package_coverage can return just tests and vignettes", {
  cov <- package_coverage("TestPrint", type = c("tests", "vignettes"), combine_types = FALSE)

  expect_equal(names(cov), c("tests", "vignettes"))
})

test_that("package_coverage with type == 'all' returns test, vignette and example coverage", {
  cov <- package_coverage("TestPrint", type = "all", combine_types = FALSE)

  expect_equal(names(cov), c("tests", "vignettes", "examples"))
})

test_that("package_coverage with type == 'none' runs no test code", {
  cov <- package_coverage("TestS4", type = "none")

  expect_equal(percent_coverage(cov), 0.00)
})

test_that("package_coverage runs additional test code", {
  cov <- package_coverage("TestS4", type = "none", code = c("a(1)", "a(2)"))

  expect_gt(percent_coverage(cov), 0.00)
})
