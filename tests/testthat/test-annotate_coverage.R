annotation_coverage <- function() {
  src <- c(
    "f <- function(x) {",
    "  if (x > 0) {",
    "    'positive'",
    "  } else {",
    "    'other'",
    "  }",
    "}",
    "",
    "# a comment",
    "g <- function(x) {",
    "  a <- 1",
    "  b <- 2",
    "  c <- 3",
    "  d <- 4",
    "  e <- 5",
    "  if (x) {",
    "    'never'",
    "  }",
    "  a + b",
    "}"
  )
  code_coverage(paste(src, collapse = "\n"), "f(1); g(FALSE)")
}

scrub_tempfile <- function(x) {
  gsub("^\\S*source\\.R[0-9a-f]+", "source.R", x)
}

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

many_chunks_coverage <- function(n = 5) {
  # Each function has one missed line, separated by covered code so that every
  # missed line is a chunk of its own with context = 0.
  src <- unlist(lapply(seq_len(n), function(i) {
    c(
      sprintf("f%d <- function(x) {", i),
      "  if (x) {",
      "    'never'",
      "  }",
      "  1",
      "}"
    )
  }))
  code_coverage(
    paste(src, collapse = "\n"),
    paste(sprintf("f%d(FALSE)", seq_len(n)), collapse = "; ")
  )
}

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
  expect_false(any(grepl("not shown", full)))
  expect_equal(annotate_coverage(cov, context = 0), full)

  withr::local_options(covr.annotate_max_lines = 1)
  expect_match(
    annotate_coverage(cov, context = 0)[[3]],
    "^  \\.\\.\\.$|not shown"
  )
  expect_equal(annotate_coverage(cov, context = 0, max_lines = Inf), full)
})
