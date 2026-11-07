local_fixture_env <- function(frame = parent.frame()) {
  src <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(
    c(
      "add <- function(x, y) {",
      "  if (x > 0) {",
      "    x + y",
      "  } else {",
      "    y",
      "  }",
      "}"
    ),
    src
  )
  env <- new.env(parent = globalenv())
  sys.source(src, envir = env, keep.source = TRUE)
  attr(env, "src") <- src
  env
}

normalize_coverage <- function(x) {
  df <- as.data.frame(x)
  df$filename <- basename(df$filename)
  df <- df[
    order(df$filename, df$first_line, df$first_byte),
    c("filename", "functions", "first_line", "last_line", "value")
  ]
  rownames(df) <- NULL
  df
}

test_that("with_coverage() measures arbitrary code run against env", {
  env <- local_fixture_env()

  cov <- with_coverage(env$add(1, 2), env = env)

  expect_s3_class(cov, "coverage")
  expect_equal(as.data.frame(cov)$value, c(1, 1, 0))
})

test_that("with_coverage() evaluates code in the calling environment", {
  env <- local_fixture_env()
  x <- 5

  cov <- with_coverage(env$add(x, 1), env = env)

  expect_equal(as.data.frame(cov)$value, c(1, 1, 0))
})

test_that("with_coverage() sets R_COVR while evaluating code", {
  env <- local_fixture_env()
  withr::local_envvar(R_COVR = NA)

  with_coverage(res <- Sys.getenv("R_COVR"), env = env)

  expect_equal(res, "true")
  expect_equal(Sys.getenv("R_COVR", ""), "")
})

test_that("with_coverage() supports exclusions", {
  env <- local_fixture_env()

  cov <- with_coverage(
    {
      env$add(1, 2)
      env$add(-1, 2)
    },
    env = env,
    line_exclusions = structure(list(3), names = attr(env, "src"))
  )

  expect_false(3 %in% as.data.frame(cov)$first_line)
})

test_that("with_coverage() restores functions and counters on success", {
  env <- local_fixture_env()
  original <- body(env$add)

  with_coverage(env$add(1, 2), env = env)

  expect_identical(body(env$add), original)
  expect_length(ls(.counters), 0)
})

test_that("with_coverage() restores functions and counters on error", {
  env <- local_fixture_env()
  original <- body(env$add)

  expect_error(
    with_coverage(
      {
        env$add(1, 2)
        stop("boom")
      },
      env = env
    ),
    "boom"
  )

  expect_identical(body(env$add), original)
  expect_length(ls(.counters), 0)
})

local_load_all <- function(pkg, frame = parent.frame()) {
  pkgload::load_all(test_path(pkg), quiet = TRUE, export_all = TRUE)
  withr::defer(pkgload::unload(pkg), envir = frame)
  asNamespace(pkg)
}

fixture_test_file <- function(pkg) {
  list.files(
    test_path(pkg, "tests", "testthat"),
    "^test.*\\.R$",
    full.names = TRUE
  )
}

test_that("with_coverage() works with testthat::test_file() on a load_all()ed package", {
  skip_if_not_installed("pkgload")

  for (pkg in c("TestSummary", "TestS4")) {
    ns <- local({
      ns <- local_load_all(pkg)
      cov <- with_coverage(
        testthat::test_file(
          fixture_test_file(pkg),
          package = pkg,
          reporter = "silent"
        ),
        env = ns
      )
      expect_equal(
        normalize_coverage(cov),
        normalize_coverage(package_coverage(test_path(pkg))),
        info = pkg
      )
      expect_length(ls(.counters), 0)
    })
  }
})

test_that("with_coverage() works with R6 classes", {
  skip_if_not_installed("pkgload")
  skip_if_not_installed("R6")

  ns <- local_load_all("TestR6")
  cov <- with_coverage(
    testthat::test_file(
      fixture_test_file("TestR6"),
      package = "TestR6",
      reporter = "silent"
    ),
    env = ns
  )

  expect_equal(
    normalize_coverage(cov),
    normalize_coverage(package_coverage(test_path("TestR6")))
  )
})

test_that("with_coverage() cleans up when a test file fails", {
  skip_if_not_installed("pkgload")

  ns <- local_load_all("TestFailure")
  original <- body(ns$covered)

  expect_error(
    with_coverage(
      testthat::test_file(
        fixture_test_file("TestFailure"),
        package = "TestFailure",
        reporter = "silent",
        stop_on_failure = TRUE
      ),
      env = ns
    ),
    "Test failures"
  )

  expect_identical(body(ns$covered), original)
  expect_length(ls(.counters), 0)
})
