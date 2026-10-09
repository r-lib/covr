test_that("function_coverage generates output", {
  env <- new.env()
  withr::with_options(c("keep.source" = TRUE), {
    eval(parse(text =
"fun <- function(x) {
  if (isTRUE(x)) {
    1
  } else {
    2
  }
}"), envir = env)
  })

  t1 <- function_coverage("fun", env = env)

  expect_equal(length(t1), 3)

  expect_equal(length(exclude(t1)), 3)

  expect_equal(length(exclude(t1, "<text>")), 0)

  expect_equal(length(exclude(t1, list("<text>" = 3))), 2)
})

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

  for (i in seq_len(5)) invisible(gc(full = FALSE))
  expect_false(state$finalized)
  # Avoid invoking a dangling closure if the GC regression returns.
  if (!state$finalized) {
    expect_identical(target(), 79L)
    expect_identical(alias(), 79L)
  }

  rm(target, alias)
  for (i in seq_len(3)) invisible(gc(full = TRUE))
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
      "f", code = quote(stopifnot(f() == 42L)), env = env, enc = env
    )
    expect_equal(percent_coverage(cov), 100)
    expect_identical(body(env$f), original_body)
  }

  rm(env)
  for (i in seq_len(3)) invisible(gc(full = TRUE))
  expect_true(state$finalized)
})
