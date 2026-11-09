test_that("missed_ranges() joins lines only across non-code lines", {
  expect_equal(missed_ranges(c(3, 6, 10), c(4, 5, 8, 9)), "3-6, 10")
  expect_equal(missed_ranges(c(3, 6, 10), c(4, 5, 7:9)), "3-10")
  expect_equal(missed_ranges(c(1, 2, 3, 112, 300)), "1-3, 112, 300")
  expect_equal(missed_ranges(c(112, 300), c(113:299)), "112-300")
  expect_equal(missed_ranges(c(112, 300), c(113:150, 152:299)), "112, 300")
  expect_equal(missed_ranges(100000), "100000")
  expect_equal(missed_ranges(integer()), "")
})

test_that("diff_coverage() counts uncommitted and untracked changes", {
  repo <- local_diff_repo()
  writeLines(
    c(
      "f <- function(x) {",
      "  # comment",
      "  if (x) {",
      "    1",
      "  } else {",
      "    2",
      "  }",
      "}"
    ),
    file.path(repo, "R", "a.R")
  )
  writeLines(
    c("g <- function() {", "  3", "}"),
    file.path(repo, "R", "b.R")
  )
  cov <- package_coverage(repo, type = "none", code = "f(TRUE); g()")
  res <- diff_coverage(cov, base = "main")

  expect_s3_class(res, "covr_diff_coverage")
  expect_setequal(unique(res$filename), c("R/a.R", "R/b.R"))
  expect_equal(res$line[res$filename == "R/a.R"], c(3, 4, 6))
  expect_equal(res$value[res$filename == "R/a.R"], c(1, 1, 0))
  expect_snapshot(print(res))
})

test_that("diff_coverage() works for a package in a subdirectory", {
  repo <- local_diff_repo(subdir = "pkg")
  pkg <- file.path(repo, "pkg")
  writeLines(
    c("f <- function() {", "  1", "}", "", "# c"),
    file.path(pkg, "R", "a.R")
  )
  cov <- package_coverage(pkg, type = "none", code = "NULL")
  res <- diff_coverage(cov, base = "main")
  expect_equal(unique(res$filename), "R/a.R")
  expect_equal(res$line, 2)
  expect_snapshot(print(res))
})

test_that("diff_coverage() reports when no code changed", {
  repo <- local_diff_repo()
  cov <- package_coverage(repo, type = "none", code = "NULL")
  expect_snapshot(print(diff_coverage(cov, base = "main")))
})

test_that("diff_coverage() errors outside a git repository", {
  skip_if_not(nzchar(Sys.which("git")))
  repo <- local_diff_repo(init = FALSE)
  cov <- package_coverage(repo, type = "none", code = "NULL")
  expect_error(diff_coverage(cov), class = "covr_diff_error")
})

test_that("diff_coverage() prints separate ranges for missed lines split by code", {
  repo <- local_diff_repo()
  path <- file.path(repo, "R", "a.R")
  code <- c(
    "f <- function(x) {",
    "  if (x) {",
    "    a <- 1",
    "  }",
    "  b <- 2",
    "  if (x) {",
    "    c <- 3",
    "  }",
    "}"
  )
  writeLines(code, path)
  git <- function(...) {
    system2(
      "git",
      c("-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", ...),
      stdout = FALSE
    )
  }
  git("add", ".")
  git("commit", "-q", "-m", "f")

  code[c(3, 7)] <- c("    a <- 10", "    c <- 30")
  writeLines(code, path)
  cov <- package_coverage(repo, type = "none", code = "f(FALSE)")
  res <- diff_coverage(cov, base = "HEAD")
  expect_equal(res$line, c(3, 7))
  expect_equal(res$value, c(0, 0))
  expect_snapshot(print(res))
})

test_that("diff_coverage() ignores diff settings in the git config", {
  withr::local_envvar(
    GIT_CONFIG_COUNT = "2",
    GIT_CONFIG_KEY_0 = "diff.noprefix",
    GIT_CONFIG_VALUE_0 = "true",
    GIT_CONFIG_KEY_1 = "diff.mnemonicPrefix",
    GIT_CONFIG_VALUE_1 = "true"
  )
  repo <- local_diff_repo()
  writeLines(c("f <- function() {", "  1", "}"), file.path(repo, "R", "a.R"))
  cov <- package_coverage(repo, type = "none", code = "NULL")
  res <- diff_coverage(cov, base = "main")
  expect_equal(res$line, 2)
})

test_that("diff_coverage() reports branches on changed lines", {
  withr::local_options(covr.branch_coverage = TRUE)
  repo <- local_diff_repo()
  writeLines(
    c(
      "f <- function(x, y) {",
      "  if (x) {",
      "    1",
      "  }",
      "  switch(y, a = 1, b = 2)",
      "}"
    ),
    file.path(repo, "R", "a.R")
  )
  writeLines(
    c(
      "g <- function(x) {",
      "  if (x) 1 else 2",
      "}",
      "h <- function(x) {",
      "  if (x) 1 else 2",
      "}"
    ),
    file.path(repo, "R", "b.R")
  )
  cov <- package_coverage(
    repo,
    type = "none",
    code = "f(TRUE, 'a'); g(TRUE); g(FALSE)"
  )
  res <- diff_coverage(cov, base = "main")

  branches <- attr(res, "branches")
  expect_equal(nrow(branches), 9)
  expect_equal(sum(branches$value == 0), 5)
  expect_equal(nrow(evaluated_missed_branches(branches)), 3)
  expect_snapshot(print(res))
})

test_that("diff_coverage() only counts branches on changed lines", {
  withr::local_options(covr.branch_coverage = TRUE)
  repo <- local_diff_repo()
  path <- file.path(repo, "R", "a.R")
  code <- c(
    "f <- function(x) {",
    "  if (x) {",
    "    1",
    "  }",
    "  x",
    "}"
  )
  writeLines(code, path)
  git <- function(...) {
    system2(
      "git",
      c("-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", ...),
      stdout = FALSE
    )
  }
  git("add", ".")
  git("commit", "-q", "-m", "f")
  code[5] <- "  x + 1"
  writeLines(code, path)
  cov <- package_coverage(repo, type = "none", code = "f(TRUE)")
  res <- diff_coverage(cov, base = "HEAD")
  expect_equal(res$line, 5)
  expect_equal(nrow(attr(res, "branches")), 0)
  expect_snapshot(print(res))
})

test_that("print.covr_diff_coverage caps ranges and branches per file", {
  lines <- seq(1, 41, by = 2)
  res <- structure(
    data.frame(filename = "R/a.R", line = lines, value = 0),
    class = c("covr_diff_coverage", "data.frame"),
    non_code_lines = list(),
    branches = data.frame(
      filename = "R/a.R",
      functions = "f",
      line = rep(lines[1:12], each = 2),
      column = 3,
      branch = rep(1:2, 12),
      label = rep(c("TRUE", "FALSE"), 12),
      value = rep(c(1, 0), 12)
    )
  )
  expect_snapshot(print(res))

  withr::local_options(covr.print_max_ranges = Inf)
  expect_false(any(grepl("more)", capture.output(print(res)))))
})
