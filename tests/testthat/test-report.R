test_that("report() bundles bootstrap 3.4.1", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- report(cov, file = file.path(withr::local_tempdir(), "report.html"))

  html <- readLines(file)
  expect_match(html, "lib/bootstrap-3.4.1/js/bootstrap.min.js", all = FALSE)
  bootstrap_js <- readLines(
    file.path(dirname(file), "lib/bootstrap-3.4.1/js/bootstrap.min.js"),
    n = 2
  )
  expect_match(bootstrap_js[[2]], "Bootstrap v3.4.1", fixed = TRUE)
})

test_that("report() works with empty coverage (#540)", {
  skip_if_not_installed("DT")
  x <- structure(list(), class = "coverage", package = list(package = "p"))
  data <- to_report_data(x)
  expect_equal(nrow(data$file_stats), 0)
  expect_named(
    data$file_stats,
    c(
      "File",
      "Lines",
      "Relevant",
      "Covered",
      "Missed",
      "Hits / Line",
      "Coverage"
    )
  )
  file <- withr::local_tempfile(fileext = ".html")
  expect_equal(report(x, file = file, browse = FALSE), file)
})
