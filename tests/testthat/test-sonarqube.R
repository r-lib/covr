test_that("it works with coverage objects", {
  tmp <- tempfile()
  cov <- package_coverage(test_path("TestSummary"))
  sonarqube(cov, filename = tmp)
  expect_equal(readLines(tmp), readLines(test_path("sonarqube.xml")))

  sonarqube(cov, filename = tmp, path_prefix = "TestSummary")
  expect_match(
    readLines(tmp),
    '<file path="TestSummary/R/TestSummary.R">',
    fixed = TRUE,
    all = FALSE
  )
})

test_that("each line is covered once, as uncovered if any of its code didn't run (#620)", {
  tmp <- tempfile()
  sonarqube(shared_line_coverage(), filename = tmp)
  doc <- xml2::read_xml(tmp)

  lines <- xml2::xml_find_all(doc, "//lineToCover")
  expect_equal(xml2::xml_attr(lines, "lineNumber"), c("2", "3", "6"))
  expect_equal(xml2::xml_attr(lines, "covered"), c("true", "false", "false"))
})

test_that("paths with XML special characters are escaped", {
  tmp <- withr::local_tempfile(fileext = ".xml")
  sonarqube(shared_line_coverage(), filename = tmp, path_prefix = "a&<b>")
  doc <- xml2::read_xml(tmp)

  path <- xml2::xml_attr(xml2::xml_find_all(doc, "//file"), "path")
  expect_match(path, "^a&<b>/")
})
