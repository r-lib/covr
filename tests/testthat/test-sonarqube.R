test_that("it works with coverage objects", {
  tmp <- withr::local_tempfile()
  cov <- package_coverage(test_path("TestSummary"))
  sonarqube(cov, file = tmp)
  expect_equal(readLines(tmp), readLines(test_path("sonarqube.xml")))

  sonarqube(cov, file = tmp, path_prefix = "TestSummary")
  expect_match(
    readLines(tmp),
    '<file path="TestSummary/R/TestSummary.R">',
    fixed = TRUE,
    all = FALSE
  )
})

test_that("each line is covered once, as uncovered if any of its code didn't run (#620)", {
  tmp <- withr::local_tempfile()
  sonarqube(shared_line_coverage(), file = tmp)
  doc <- xml2::read_xml(tmp)

  lines <- xml2::xml_find_all(doc, "//lineToCover")
  expect_equal(xml2::xml_attr(lines, "lineNumber"), c("2", "3", "6"))
  expect_equal(xml2::xml_attr(lines, "covered"), c("true", "false", "false"))
})

test_that("compiled code, which has no function names, is reported", {
  cov <- code_coverage("f <- function() 1\ng <- function() 2", "f()")
  cov[[2]]$functions <- NA_character_
  tmp <- withr::local_tempfile(fileext = ".xml")
  sonarqube(cov, file = tmp)
  doc <- xml2::read_xml(tmp)

  lines <- xml2::xml_find_all(doc, "//lineToCover")
  expect_equal(xml2::xml_attr(lines, "lineNumber"), c("1", "2"))
  expect_equal(xml2::xml_attr(lines, "covered"), c("true", "false"))
})

test_that("lines with branches have their branches to cover", {
  tmp <- withr::local_tempfile(fileext = ".xml")
  cov <- branch_coverage(
    c(
      "f <- function(x) {",
      "  if (x > 0) 'positive'",
      "  'done'",
      "}",
      "g <- function(x) switch(x, a = 1, b = 2)",
      "h <- function() 1"
    ),
    "f(1); g('a')"
  )
  sonarqube(cov, file = tmp)
  lines <- xml2::xml_find_all(xml2::read_xml(tmp), "//lineToCover")

  expect_equal(xml2::xml_attr(lines, "lineNumber"), c("2", "3", "5", "6"))
  expect_equal(xml2::xml_attr(lines, "branchesToCover"), c("2", NA, "3", NA))
  expect_equal(xml2::xml_attr(lines, "coveredBranches"), c("1", NA, "1", NA))
})

test_that("branches are not reported without branch coverage", {
  tmp <- withr::local_tempfile(fileext = ".xml")
  cov <- code_coverage("f <- function(x) if (x) 1", "f(TRUE)")
  sonarqube(cov, file = tmp)
  doc <- xml2::read_xml(tmp)

  expect_length(xml2::xml_find_all(doc, "//lineToCover[@branchesToCover]"), 0)
})

test_that("paths with XML special characters are escaped", {
  tmp <- withr::local_tempfile(fileext = ".xml")
  sonarqube(shared_line_coverage(), file = tmp, path_prefix = "a&<b>")
  doc <- xml2::read_xml(tmp)

  path <- xml2::xml_attr(xml2::xml_find_all(doc, "//file"), "path")
  expect_match(path, "^a&<b>/")
})
