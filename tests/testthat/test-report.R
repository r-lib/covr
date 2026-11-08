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
  report(x, file = file, browse = FALSE)
  expect_true(file.exists(file))
})

test_that("report() uses the default colors (#529)", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")
  withr::local_options(covr.report_colors = NULL)

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- report(cov, file = withr::local_tempfile(fileext = ".html"))
  html <- paste(readLines(file), collapse = "\n")

  expect_match(
    html,
    "table tr.covered td{\n  background-color:rgba(95,151,68,0.3)\n}",
    fixed = TRUE
  )
  expect_match(
    html,
    "table tr:hover.missed .num{\n  background-color:rgba(185,73,71,0.7)\n}",
    fixed = TRUE
  )
  expect_match(html, "box-shadow:0 -2px 0 0 #5f9744 inset", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #b94947 inset", fixed = TRUE)
  expect_match(html, "linear-gradient(90deg, #edfde7 ", fixed = TRUE)
  expect_match(html, "linear-gradient(90deg, #f9ffe5 ", fixed = TRUE)
  expect_match(html, "linear-gradient(90deg, #fcece9 ", fixed = TRUE)
})

test_that("report() and file_report() use covr.report_colors (#529)", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")
  withr::local_options(
    covr.report_colors = c(covered = "#0072B2", missed = "orange")
  )

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- report(cov, file = withr::local_tempfile(fileext = ".html"))
  html <- paste(readLines(file), collapse = "\n")
  expect_match(html, "background-color:rgba(0,114,178,0.3)", fixed = TRUE)
  expect_match(html, "background-color:rgba(255,165,0,0.3)", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #0072b2 inset", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #ffa500 inset", fixed = TRUE)
  expect_match(html, "linear-gradient(90deg, #e0eef6 ", fixed = TRUE)
  expect_match(html, "linear-gradient(90deg, #fff4e0 ", fixed = TRUE)
  expect_no_match(html, "95,151,68|185,73,71|#5f9744|#b94947|#edfde7|#fcece9")

  file <- file_report(
    cov,
    out_file = withr::local_tempfile(fileext = ".html"),
    browse = FALSE
  )
  html <- paste(readLines(file), collapse = "\n")
  expect_match(html, "background-color:rgba(0,114,178,0.3)", fixed = TRUE)
  expect_match(html, "background-color:rgba(255,165,0,0.3)", fixed = TRUE)
})

test_that("covr.report_colors can set only one color (#529)", {
  colors <- report_colors(c(missed = "#E69F00"))
  expect_equal(colors[, "covered"], c(red = 95, green = 151, blue = 68))
  expect_equal(colors[, "missed"], c(red = 230, green = 159, blue = 0))
  expect_equal(
    coverage_tints(colors),
    c(high = "#edfde7", mid = "#f9ffe5", low = "#fcf3e0")
  )
})

test_that("covr.report_colors is validated (#529)", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")
  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  local_report_colors <- function(colors) {
    withr::local_options(
      covr.report_colors = colors,
      .local_envir = parent.frame()
    )
  }

  local_report_colors(c("blue", "orange"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(c(covered = "blue", hit = "orange"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(list(covered = "blue"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(c(covered = "notacolor"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  expect_snapshot(file_report(cov, browse = FALSE), error = TRUE)
})
