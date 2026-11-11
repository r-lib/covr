test_that("reassigned closures keep young fields alive without retaining them forever", {
  state <- new.env(parent = emptyenv())
  state$finalized <- FALSE
  finalize <- function(env) state$finalized <- TRUE
  target <- function() 0L
  alias <- target

  # Age the target before creating its replacement. Keep the replacement free
  # of attributes, whose own write barrier could otherwise mask this bug.
  invisible(gc(full = TRUE))
  invisible(gc(full = TRUE))
  local({
    env <- new.env(parent = baseenv())
    env$payload <- 37L
    reg.finalizer(env, finalize)
    replacement <- eval(
      parse(text = "function(x = 42L) x + payload", keep.source = FALSE),
      envir = env
    )
    .Call(covr_reassign_function, target, replacement)
  })

  for (i in seq_len(5)) {
    invisible(gc(full = FALSE))
  }
  expect_false(state$finalized)
  # Avoid invoking a dangling closure if the GC regression returns.
  if (!state$finalized) {
    expect_identical(target(), 79L)
    expect_identical(alias(), 79L)
  }

  rm(target, alias)
  for (i in seq_len(3)) {
    invisible(gc(full = TRUE))
  }
  expect_true(state$finalized)
})

test_that("reassignment restores attributes and S4 flags without changing its source", {
  target <- function() 0L
  replacement <- asS4(function(x = 2L) x + 3L)
  attr(replacement, "covr_gc_anchor") <- "user data"
  attr(replacement, "custom") <- list(value = "kept")
  attrs <- attributes(replacement)

  .Call(covr_reassign_function, target, replacement)
  expect_identical(target(), 5L)
  expect_true(isS4(target))
  expect_identical(attributes(target), attrs)
  expect_identical(attributes(replacement), attrs)

  .Call(covr_reassign_function, target, target)
  expect_identical(target(), 5L)
  expect_true(isS4(target))
  expect_identical(attributes(target), attrs)
})

test_that("function coverage restores closures and releases their local environments", {
  state <- new.env(parent = emptyenv())
  state$finalized <- FALSE
  finalize <- function(env) state$finalized <- TRUE
  env <- new.env(parent = baseenv())
  reg.finalizer(env, finalize)
  withr::with_options(list(keep.source = TRUE), {
    eval(parse(text = "f <- function() { 42L }"), envir = env)
  })
  original_body <- body(env$f)

  for (i in seq_len(3)) {
    cov <- function_coverage(
      "f",
      code = quote(stopifnot(f() == 42L)),
      env = env,
      enc = env
    )
    expect_equal(percent_coverage(cov), 100)
    expect_identical(body(env$f), original_body)
  }

  rm(env)
  for (i in seq_len(3)) {
    invisible(gc(full = TRUE))
  }
  expect_true(state$finalized)
})

test_that("it works on memoised functions", {
  skip_if_not_installed("memoise")
  s1 <- local_r_file(
    "a <- memoise::memoise(function(x) {
  x + 1
})"
  )
  t1 <- local_r_file(
    "
a(1)
a(1)
a(1)
a(1)
a(2)
a(3)"
  )

  cov <- file_coverage(s1, t1)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, "a")
  expect_equal(cov_d$value, 3)
})

test_that("with_coverage() restores the function a memoised wrapper calls", {
  skip_if_not_installed("memoise")
  src <- withr::local_tempfile(
    fileext = ".R",
    lines = "a <- memoise::memoise(function(x) {\n  x + 1\n})"
  )
  env <- new.env()
  sys.source(src, envir = env, keep.source = TRUE)
  inner <- environment(env$a)[["_f"]]
  original <- body(inner)

  cov <- with_coverage(env$a(1), env = env)
  expect_equal(as.data.frame(cov)$value, 1)
  expect_identical(environment(env$a)[["_f"]], inner)
  expect_identical(body(inner), original)

  cov <- with_coverage(env$a(2), env = env)
  expect_equal(as.data.frame(cov)$value, 1)
  expect_identical(body(inner), original)
})
