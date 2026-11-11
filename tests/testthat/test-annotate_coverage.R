test_that("annotate_coverage shows missed lines with context", {
  cov <- annotation_coverage()
  expect_s3_class(annotate_coverage(cov), "covr_annotation")
  expect_snapshot(annotate_coverage(cov), transform = scrub_tempfile)
})

test_that("annotate_coverage supports context = 0 and Inf", {
  cov <- annotation_coverage()
  expect_snapshot(
    annotate_coverage(cov, context = 0),
    transform = scrub_tempfile
  )
  expect_snapshot(
    annotate_coverage(cov, context = Inf),
    transform = scrub_tempfile
  )
})

test_that("annotate_coverage filters by files", {
  cov <- annotation_coverage()
  expect_snapshot(
    annotate_coverage(cov, files = "no_such_file.R"),
    transform = scrub_tempfile
  )
  expect_equal(
    unclass(annotate_coverage(
      cov,
      files = unique(zero_coverage(cov)$filename)
    )),
    unclass(annotate_coverage(cov))
  )
})

test_that("annotate_coverage accepts custom lines", {
  cov <- annotation_coverage()
  filename <- unique(zero_coverage(cov)$filename)
  lines <- data.frame(filename = filename, line = c(3, 11))
  expect_snapshot(
    annotate_coverage(cov, lines = lines, context = 1),
    transform = scrub_tempfile
  )
})

test_that("annotate_coverage reports when nothing is missed", {
  cov <- code_coverage("f <- function() 1", "f()")
  expect_snapshot(annotate_coverage(cov), transform = scrub_tempfile)
})

test_that("annotate_coverage shows missed branches", {
  withr::local_options(covr.branch_coverage = TRUE)
  src <- c(
    "f <- function(x, y) {",
    "  if (x) {",
    "    'yes'",
    "  }",
    "  switch(y, a = 1, b = 2)",
    "}",
    "h <- function(x) {",
    "  if (x) 1 else 2",
    "}"
  )
  cov <- code_coverage(paste(src, collapse = "\n"), "f(TRUE, 'a')")
  expect_snapshot(annotate_coverage(cov), transform = scrub_tempfile)
  expect_snapshot(
    annotate_coverage(
      cov,
      lines = data.frame(
        filename = unique(tally_coverage(cov, by = "branch")$filename),
        line = 3
      ),
      context = 0
    ),
    transform = scrub_tempfile
  )
})

test_that("annotate_coverage is unchanged without branch coverage", {
  cov <- code_coverage("f <- function(x) {\n  if (x) 1\n}", "f(TRUE)")
  expect_equal(nrow(tally_coverage(cov, by = "branch")), 0)
  expect_equal(
    unclass(annotate_coverage(cov)),
    "No missed lines."
  )
})

test_that("annotate_coverage stops at max_lines with a summary line", {
  cov <- many_chunks_coverage()
  expect_snapshot(
    annotate_coverage(cov, context = 0, max_lines = 2),
    transform = scrub_tempfile
  )
  res <- annotate_coverage(cov, context = 0, max_lines = 3)
  expect_match(
    res[length(res)],
    "... 2 more lines in 1 file not shown; narrow with `files` or `lines`, or raise `max_lines`.",
    fixed = TRUE
  )
  # Whole chunks only
  expect_equal(sum(grepl("'never'", res)), 3)
})

test_that("annotate_coverage counts the files left out", {
  cov <- many_chunks_coverage(2)
  res <- annotate_coverage(cov, context = 0, max_lines = 1)
  expect_match(res[length(res)], "^\\.\\.\\. 1 more line in 1 file ")
  lines <- data.frame(
    filename = rep(c("a.R", "b.R"), each = 2),
    line = c(1, 5, 1, 5)
  )
  local_mocked_bindings(
    traced_files = function(x) {
      list(
        a.R = list(file_lines = rep("x", 10)),
        b.R = list(file_lines = rep("y", 10))
      )
    }
  )
  res <- annotate_coverage(cov, lines = lines, context = 0, max_lines = 1)
  expect_equal(res[[1]], "a.R")
  expect_match(res[length(res)], "^\\.\\.\\. 3 more lines in 2 files")
})

test_that("annotate_coverage always shows the first chunk", {
  cov <- many_chunks_coverage()
  res <- annotate_coverage(cov, context = 2, max_lines = 0)
  expect_equal(sum(grepl("^  +\\d+ \\|", res)), 5)
  expect_match(res[length(res)], "^\\.\\.\\. 4 more lines in 1 file ")
})

test_that("annotate_coverage max_lines = Inf and the option disable the cap", {
  cov <- many_chunks_coverage()
  full <- annotate_coverage(cov, context = 0, max_lines = Inf)
  expect_no_match(full, "not shown")
  expect_equal(annotate_coverage(cov, context = 0), full)

  withr::local_options(covr.annotate_max_lines = 1)
  expect_match(
    annotate_coverage(cov, context = 0)[[3]],
    "^  \\.\\.\\.$|not shown"
  )
  expect_equal(annotate_coverage(cov, context = 0, max_lines = Inf), full)
})

test_that("annotate_coverage checks max_lines and context", {
  cov <- annotation_coverage()
  expect_snapshot(error = TRUE, {
    annotate_coverage(cov, max_lines = "a")
    annotate_coverage(cov, context = NA)
  })
})
