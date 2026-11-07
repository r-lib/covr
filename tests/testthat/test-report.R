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
