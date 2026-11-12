test_that("it writes an SVG badge with the percent coverage", {
  cov <- code_coverage(
    "f <- function(x) {\n  y <- x + 1\n  if (y > 0) {\n    'yes'\n  } else {\n    'no'\n  }\n}",
    "f(1)"
  )
  tmp <- withr::local_tempfile(fileext = ".svg")
  out <- badge(cov, tmp)
  expect_equal(readLines(tmp), out)
  expect_snapshot(writeLines(out))
})

test_that("numbers use a period regardless of OutDec", {
  cov <- code_coverage("f <- function() 1", "f()")
  expected <- badge(cov, withr::local_tempfile())
  withr::local_options(OutDec = ",")
  out <- badge(cov, withr::local_tempfile())
  expect_equal(out, expected)
  expect_match(out, 'x="30.5"', fixed = TRUE, all = FALSE)
})

test_that("coverage is rounded down and colored by the report thresholds", {
  title_and_color <- function(percent) {
    local_mocked_bindings(percent_coverage = function(x, ...) percent)
    svg <- xml2::read_xml(paste(
      badge(NULL, withr::local_tempfile()),
      collapse = "\n"
    ))
    xml2::xml_ns_strip(svg)
    c(
      xml2::xml_text(xml2::xml_find_first(svg, "/svg/title")),
      xml2::xml_attr(xml2::xml_find_all(svg, "/svg/g/rect")[[2]], "fill")
    )
  }

  expect_equal(title_and_color(100), c("coverage: 100%", "#4c1"))
  expect_equal(title_and_color(99.99), c("coverage: 99%", "#4c1"))
  expect_equal(title_and_color(90), c("coverage: 90%", "#4c1"))
  expect_equal(title_and_color(89.99), c("coverage: 89%", "#dfb317"))
  expect_equal(title_and_color(75), c("coverage: 75%", "#dfb317"))
  expect_equal(title_and_color(74.99), c("coverage: 74%", "#e05d44"))
  expect_equal(title_and_color(0), c("coverage: 0%", "#e05d44"))
  expect_equal(title_and_color(NaN), c("coverage: unknown", "#9f9f9f"))
})

test_that("coverage without lines of code is unknown", {
  cov <- code_coverage("", "")
  out <- badge(cov, withr::local_tempfile())
  expect_match(
    out,
    "<title>coverage: unknown</title>",
    fixed = TRUE,
    all = FALSE
  )
})

test_that("the label is escaped and sizes the badge", {
  cov <- code_coverage("f <- function() 1", "f()")
  out <- badge(cov, withr::local_tempfile(), label = "R & <C> \"code\"")
  svg <- xml2::read_xml(paste(out, collapse = "\n"))
  xml2::xml_ns_strip(svg)
  expect_equal(
    xml2::xml_text(xml2::xml_find_all(svg, "/svg/g/text")),
    rep(c("R & <C> \"code\"", "100%"), each = 2)
  )

  short <- badge(cov, withr::local_tempfile(), label = "cov")
  width <- function(out) {
    as.numeric(xml2::xml_attr(
      xml2::read_xml(paste(out, collapse = "\n")),
      "width"
    ))
  }
  expect_lt(width(short), width(out))
})

test_that("label must be a single string", {
  cov <- code_coverage("f <- function() 1", "f()")
  tmp <- withr::local_tempfile()
  expect_snapshot(
    error = TRUE,
    badge(cov, tmp, label = c("a", "b"))
  )
  expect_snapshot(error = TRUE, badge(cov, tmp, label = NA))
})
