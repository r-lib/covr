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

test_that("methods only list the lines of their own file (#629)", {
  skip_if_not_installed("R6")
  a <- local_r_file(c(
    "A <- R6::R6Class('A', public = list(",
    "  initialize = function() {",
    "    self$x <- 1",
    "  },",
    "  x = NULL",
    "))"
  ))
  b <- local_r_file(c(
    rep("# padding", 10),
    "B <- R6::R6Class('B', public = list(",
    "  initialize = function() {",
    "    self$x <- 2",
    "  },",
    "  x = NULL",
    "))"
  ))
  test <- local_r_file("A$new()")
  cov <- file_coverage(c(a, b), test)

  tmp <- withr::local_tempfile(fileext = ".xml")
  to_cobertura(cov, filename = tmp)
  doc <- xml2::read_xml(tmp)

  method <- function(file) {
    xml2::xml_find_first(
      doc,
      sprintf("//class[@filename='%s']//method[@name='initialize']", file)
    )
  }
  method_lines <- function(file) {
    xml2::xml_attr(xml2::xml_find_all(method(file), "lines/line"), "number")
  }
  expect_equal(method_lines(a), "3")
  expect_equal(xml2::xml_attr(method(a), "line-rate"), "1")
  expect_equal(method_lines(b), "13")
  expect_equal(xml2::xml_attr(method(b), "line-rate"), "0")
})
