context("cobertura_export")

test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))

  # fix host-dependent report parameters
  mockery::stub(
    to_cobertura,
    "utils::packageVersion",
    structure(
      list(c(3L, 2L, 1L, 9000L)),
      class = c("package_version", "numeric_version")
    )
  )
  mockery::stub(to_cobertura, "getwd", "/dummy/directory")
  mockery::stub(
    to_cobertura, "Sys.time",
    as.POSIXct("2019-08-05 05:26:36")
  )

  to_cobertura(cov, filename = tmp)

  expect_equal(
    readLines(tmp)[c(-1, -2)],
    readLines(test_path("cobertura.xml"))[c(-1, -2)]
  )
})
