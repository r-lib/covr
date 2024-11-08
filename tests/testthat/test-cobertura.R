test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))

  attr(cov, "package")$path <- "/dummy/directory"
  to_cobertura(cov, filename = tmp)

  expect_equal(
    readLines(tmp)[c(-1, -2, -3)],
    readLines(test_path("cobertura.xml"))[c(-1, -2, -3)]
  )
})
