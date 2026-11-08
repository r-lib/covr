# Extracted from test-file_coverage.R:78

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "covr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
s1 <- tempfile()
t1 <- tempfile()
writeLines(
  con = s1,
  "a <- function(x) {
  x + 1
}

b <- function(x) {
  if (x > 1) TRUE
  else FALSE
}"
)
writeLines(
  con = t1,
  "a(1)
a(2)
a(3)
b(0)
b(1)
b(2)"
)
on.exit(unlink(c(s1, t1)))

# test -------------------------------------------------------------------------
withr::local_envvar(NOT_CRAN = "true")
dir <- withr::local_tempdir()
src <- file.path(dir, "fn.R")
test <- file.path(dir, "test-fn.R")
writeLines("fn <- function(x) if (x > 0) 'positive' else 'not positive'", src)
writeLines(
    c(
      "test_that('fn', {",
      "  local_edition(3)",
      "  expect_snapshot(fn(1))",
      "})"
    ),
    test
  )
run <- function() {
    file_coverage(
      src,
      test,
      runner = function(file, env) {
        testthat::test_file(file, env = env, reporter = "silent")
      }
    )
  }
run()
expect_true(file.exists(file.path(dir, "_snaps", "fn.md")))
cov <- run()
expect_equal(percent_coverage(cov), 100)
