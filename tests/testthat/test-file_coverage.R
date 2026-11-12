test_that("it works on single files", {
  files <- local_ab_files()
  cov <- file_coverage(files$src, files$test)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, c("a", "b", "b", "b"))
  expect_equal(cov_d$value, c(3, 3, 1, 2))
})

test_that("runner is called with each test file and the source environment", {
  files <- local_ab_files()
  calls <- list()
  runner <- function(file, env) {
    calls[[length(calls) + 1L]] <<- list(file = file, env = env)
    sys.source(file, envir = env)
  }
  cov <- file_coverage(files$src, files$test, runner = runner)

  expect_length(calls, 1)
  expect_equal(calls[[1]]$file, files$test)
  expect_type(get("a", envir = calls[[1]]$env), "closure")
  expect_equal(as.data.frame(cov)$value, c(3, 3, 1, 2))
})

test_that("runner = testthat::test_file supports expect_snapshot() (#501)", {
  withr::local_envvar(NOT_CRAN = "true")
  dir <- withr::local_tempdir()
  src <- file.path(dir, "fn.R")
  test <- file.path(dir, "test-fn.R")
  writeLines(c("fn <- function(x) {", "  paste(x, 'is positive')", "}"), src)
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

  # The first run creates the snapshot, the second compares against it
  run()
  expect_true(file.exists(file.path(dir, "_snaps", "fn.md")))
  cov <- run()
  expect_equal(percent_coverage(cov), 100)
})
