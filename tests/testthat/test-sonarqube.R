test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))
  to_sonarqube(cov, filename = tmp)
  expect_equal(readLines(tmp), readLines(test_path("sonarqube.xml")))
})
