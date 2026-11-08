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

test_that("each line is counted once, as uncovered if any of its code didn't run (#620)", {
  tmp <- tempfile()
  to_cobertura(shared_line_coverage(), filename = tmp)
  doc <- xml2::read_xml(tmp)

  top <- xml2::xml_find_first(doc, "/coverage")
  expect_equal(xml2::xml_attr(top, "lines-valid"), "3")
  expect_equal(xml2::xml_attr(top, "lines-covered"), "1")

  lines <- xml2::xml_find_all(doc, "//class/lines/line")
  expect_equal(xml2::xml_attr(lines, "number"), c("2", "3", "6"))
  expect_equal(xml2::xml_attr(lines, "hits"), c("1", "0", "0"))
})
