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

test_that("tracing env again keeps the counts and traces new functions (#641)", {
  env <- local_fixture_env()
  sub <- local_r_file(c("sub <- function(x, y) {", "  x - y", "}"))

  cov <- with_coverage(
    {
      env$add(1, 2)
      sys.source(sub, envir = env, keep.source = TRUE)
      trace_environment(env)
      env$add(-1, 2)
      env$sub(1, 2)
    },
    env = env
  )

  df <- as.data.frame(cov)
  df <- df[order(df$functions, df$first_line), ]
  expect_equal(df$functions, c("add", "add", "add", "sub"))
  expect_equal(df$first_line, c(2, 3, 5, 2))
  expect_equal(df$value, c(2, 1, 1, 1))
  expect_identical(is_traced(env$sub), FALSE)
})

test_that("tracing env again traces functions replaced since (#641)", {
  env <- local_fixture_env()
  new_add <- local_r_file(c("add <- function(x, y) {", "  x - y", "}"))

  cov <- with_coverage(
    {
      env$add(1, 2)
      sys.source(new_add, envir = env, keep.source = TRUE)
      trace_environment(env)
      env$add(1, 2)
      env$add(1, 2)
    },
    env = env
  )

  df <- as.data.frame(cov)
  df <- df[order(df$filename == attr(env, "src"), df$first_line), ]
  expect_equal(df$first_line, c(2, 2, 3, 5))
  expect_equal(df$value, c(2, 1, 1, 0))
  expect_identical(is_traced(env$add), FALSE)
})

test_that("tracing env again traces nested functions added since (#641)", {
  withr::local_options(covr.full_traversal = TRUE)
  env <- new.env(parent = globalenv())
  fns <- local_r_file(c("fns <- list(", "  a = function() 1", ")"))
  add_b <- local_r_file("fns$b <- function() 2")
  sys.source(fns, envir = env, keep.source = TRUE)

  cov <- with_coverage(
    {
      env$fns$a()
      sys.source(add_b, envir = env, keep.source = TRUE)
      trace_environment(env)
      env$fns$a()
      env$fns$b()
    },
    env = env
  )

  df <- as.data.frame(cov)
  df <- df[order(df$functions), ]
  expect_equal(df$functions, c("fns$a", "fns$b"))
  expect_equal(df$value, c(2, 1))
})

test_that("traces can be reset and reused after tracing env again with record_tests (#641)", {
  withr::local_options(covr.record_tests = TRUE)
  env <- local_fixture_env()
  original <- body(env$add)

  trace_environment(env)
  trace_environment(env)
  reset_traces()
  clear_counters()
  expect_identical(body(env$add), original)

  cov <- with_coverage(
    {
      env$add(1, 2)
      trace_environment(env)
      env$add(-1, 2)
    },
    env = env
  )
  expect_identical(body(env$add), original)
  expect_equal(as.data.frame(cov)$value, c(2, 1, 1))
  # Each hit, before and after tracing again, is recorded
  expect_equal(
    vapply(cov, function(x) nrow(x$tests), integer(1)),
    vapply(cov, function(x) as.integer(x$value), integer(1))
  )

  cov <- with_coverage(env$add(1, 2), env = env)
  expect_equal(as.data.frame(cov)$value, c(1, 1, 0))
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

# Run a fixture's test file, capturing what its tests print
quiet_test_file <- function(pkg, ...) {
  utils::capture.output(
    res <- testthat::test_file(
      fixture_test_file(pkg),
      package = pkg,
      reporter = "silent",
      ...
    )
  )
  invisible(res)
}

test_that("with_coverage() works with testthat::test_file() on a load_all()ed package", {
  skip_if_not_installed("pkgload")

  for (pkg in c("TestSummary", "TestS4")) {
    ns <- local({
      ns <- local_load_all(pkg)
      cov <- with_coverage(
        quiet_test_file(pkg),
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
  # package_coverage() of TestR6 is wrong during R CMD check on R-devel (see
  # the skip in test-R6.R), so the reference can't be computed there
  skip_if(is_r_devel())

  ns <- local_load_all("TestR6")
  cov <- with_coverage(
    quiet_test_file("TestR6"),
    env = ns
  )

  expect_equal(
    normalize_coverage(cov),
    normalize_coverage(package_coverage(test_path("TestR6")))
  )
})

test_that("with_coverage() works with tests that read fixtures with test_path() (#551)", {
  skip_if_not_installed("pkgload")

  ns <- local_load_all("TestFixtures")
  cov <- with_coverage(
    quiet_test_file("TestFixtures", stop_on_failure = TRUE),
    env = ns
  )

  expect_equal(percent_coverage(cov), 100)
})

test_that("with_coverage() cleans up when a test file fails", {
  skip_if_not_installed("pkgload")

  ns <- local_load_all("TestFailure")
  original <- body(ns$covered)

  expect_error(
    with_coverage(
      quiet_test_file("TestFailure", stop_on_failure = TRUE),
      env = ns
    ),
    "Test failures"
  )

  expect_identical(body(ns$covered), original)
  expect_length(ls(.counters), 0)
})
