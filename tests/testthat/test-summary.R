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
  expect_equal(res, 80)
})

test_that("a line is only covered if all its expressions ran (#620)", {
  cov <- shared_line_coverage()

  res <- tally_coverage(cov)
  expect_equal(res$line, c(2, 3, 6, 6))
  expect_equal(res$value, c(1, 0, 1, 0))

  expect_equal(percent_coverage(cov), 100 / 3)
  expect_equal(coverage_to_list(cov)$totalcoverage, 33.33)
  expect_equal(as.vector(coverage_to_list(cov)$filecoverage), 33.33)
  expect_equal(unclass(coverage_to_markdown(cov))[[3]], "| Total | 33.33% |")
})

test_that("tally_coverage() is fast with thousands of expressions on a line (#620)", {
  skip_on_cran()
  n <- 2000
  df <- data.frame(
    filename = "a.R",
    functions = "f",
    first_line = c(1, rep(2, n)),
    first_byte = c(1, seq(1, by = 5, length.out = n)),
    last_line = c(3, rep(2, n)),
    last_byte = c(10, seq(4, by = 5, length.out = n)),
    value = c(1, rep(2, n - 1), 0),
    stringsAsFactors = FALSE
  )

  time <- system.time(res <- tally_coverage(df))[["elapsed"]]
  expect_lt(time, 2)
  expect_equal(res$value, c(1, 0, 1))
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

test_that("coverage_to_markdown() escapes file names and handles missing/lower base", {
  skip_on_os("windows")
  src <- "f <- function(x) {\n  if (x) {\n    1\n  }\n  2\n}"
  dir <- withr::local_tempdir()
  writeLines(src, file.path(dir, "a|b<c>.R"))
  writeLines(sub("^f", "g", src), file.path(dir, "new.R"))
  writeLines("f(TRUE)\ng(TRUE)", file.path(dir, "full.R"))
  writeLines("f(FALSE)", file.path(dir, "part.R"))
  withr::local_dir(dir)
  full <- file_coverage(c("a|b<c>.R", "new.R"), "full.R")
  part <- file_coverage("a|b<c>.R", "part.R")
  expect_snapshot({
    coverage_to_markdown(full)
    coverage_to_markdown(full, base = part)
    coverage_to_markdown(part, base = full)
  })
})
