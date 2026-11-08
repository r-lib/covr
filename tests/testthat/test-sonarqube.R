test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))
  to_sonarqube(cov, filename = tmp)
  expect_equal(readLines(tmp), readLines(test_path("sonarqube.xml")))

  to_sonarqube(cov, filename = tmp, path_prefix = "TestSummary")
  expect_match(
    readLines(tmp),
    '<file path="TestSummary/R/TestSummary.R">',
    fixed = TRUE,
    all = FALSE
  )
})
