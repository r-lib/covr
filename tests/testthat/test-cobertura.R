context("cobertura_export")

test_that("it works with coverage objects", {
  skip_on_cran()
  tmp <- tempfile()
  cov <- package_coverage("TestSummary")
  to_cobertura(cov, filename = tmp)
  expect_equal(readLines(tmp)[-2], readLines("cobertura.xml")[-2])
})
