test_that("coverage measured in this process keeps its coverage", {
  expect_equal(outer_fun(1), 2)
  cov <- covr::code_coverage("f <- function() 1", "f()")
  expect_equal(covr::percent_coverage(cov), 100)
  expect_equal(outer_fun(2), 3)
})

test_that("package_coverage() measures a package that imports this one", {
  inner <- Sys.getenv("COVR_NESTED_INNER")
  skip_if(inner == "")
  cov <- covr::package_coverage(inner)
  expect_equal(covr::tally_coverage(cov)$value, c(1, 1))
})
