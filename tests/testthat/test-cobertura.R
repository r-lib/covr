context("cobertura_export")

test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))
  to_cobertura(cov, filename = tmp)
  expect_equal(readLines(tmp)[c(-1, -2)], readLines(test_path("cobertura.xml"))[c(-1, -2)])
})
