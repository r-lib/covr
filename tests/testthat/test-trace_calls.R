context("trace_calls")
test_that("one-line functions are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x + 1

  expect_equal(as.character(body(trace_calls(fun))[[2]][[1]]),
      c(":::", "covr", "count"))

  fun <- function() 1

  expect_equal(as.character(body(trace_calls(fun))[[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[3]], body(fun))
})
test_that("one-line functions with no calls are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x

  expect_equal(as.character(body(trace_calls(fun))[[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[3]], body(fun))
})
test_that("one-line functions with braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) {
    x + 1
  }

  expect_equal(as.character(body(trace_calls(fun))[[2]][[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[2]][[3]], body(fun)[[2]])
})

test_that("one-line functions with no calls and braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
    1
  }

  e2 <- body(trace_calls(fun))[[2]]
  expect_true(length(e2) > 1 &&
              identical(as.character(e2[[2]][[1]]), c(":::", "covr", "count")))

  fun <- function(x) {
    x
  }

  e2 <- body(trace_calls(fun))[[2]]

  # the second expr should be a block
  expect_true(length(e2) > 1 &&
    identical(as.character(e2[[2]][[1]]), c(":::", "covr", "count")))
})


test_that("last evaled expression is traced", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
    x <- 1
    x
  }

  body <- body(trace_calls(fun))

  expect_equal(length(body), 3)

  # last expression: the implicit return expression
  e3 <- body[[3]]
  expect_true(length(e3) > 1 &&
    identical(as.character(e3[[2]][[1]]), c(":::", "covr", "count")))

})

test_that("functions with NULL bodies are traced correctly", {
  old <- options(keep.source = TRUE)
  on.exit(options(old))

  fun <- function() NULL

  expect_null(trace_calls(fun)())
})
