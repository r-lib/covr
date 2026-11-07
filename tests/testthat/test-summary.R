test_that("Summary gives 50% coverage and two lines with zero coverage", {
  cv <- package_coverage(test_path("TestSummary"))
  expect_equal(percent_coverage(cv), 50)
  expect_equal(nrow(zero_coverage(cv)), 2)
})

test_that("tally_coverage() and zero_coverage() by function", {
  cov <- code_coverage(
    paste(
      "f <- function(x) {",
      "  if (x) {",
      "    1",
      "  } else {",
      "    2",
      "  }",
      "}",
      "g <- function() {",
      "  h <- function() 3",
      "  h()",
      "}",
      "k <- function() {",
      "  4",
      "}",
      sep = "\n"
    ),
    "f(TRUE); f(TRUE); g()"
  )

  res <- tally_coverage(cov, by = "function")
  expect_named(
    res,
    c("filename", "functions", "first_line", "last_line", "value")
  )
  expect_equal(res$functions, c("f", "g", "k"))
  expect_equal(res$first_line, c(2, 9, 13))
  expect_equal(res$last_line, c(5, 10, 13))
  expect_equal(res$value, c(2, 1, 0))

  expect_equal(zero_coverage(cov, by = "function")$functions, "k")
  expect_equal(percent_coverage(cov, by = "function"), 200 / 3)
})

test_that("percent_coverage", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old), add = TRUE)

  fun <- function() {
    x <- 1
    if (x > 2) {
      print(x)
    }
    res <- lapply(1:2, function(x) {
      x + 1
    })
  }
  cov <- function_coverage("fun", env = environment(fun), fun())

  res <- percent_coverage(cov)
  expect_equal(res, 83.333333, tolerance = .01)
})

test_that("coverage_to_markdown() formats totals, files and differences", {
  src <- "f <- function(x) {\n  if (x) {\n    1\n  }\n  2\n}"
  dir <- withr::local_tempdir()
  writeLines(src, file.path(dir, "f.R"))
  writeLines("f(TRUE)", file.path(dir, "full.R"))
  writeLines("f(FALSE)", file.path(dir, "part.R"))
  withr::local_dir(dir)
  full <- file_coverage("f.R", "full.R")
  part <- file_coverage("f.R", "part.R")
  expect_snapshot(
    {
      coverage_to_markdown(part)
      coverage_to_markdown(full, base = part)
    }
  )
})
