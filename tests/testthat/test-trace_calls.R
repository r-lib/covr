context("trace_calls")
test_that("one-line functions are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x + 1

  expect_equal(as.character(body(trace_calls(fun))[[2]][[1]])[3], "count")

  expect_equal(body(trace_calls(fun))[[3]], body(fun))
})
test_that("one-line functions with no calls are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x

  expect_equal(as.character(body(trace_calls(fun))[[2]][[1]])[3], "count")

  expect_equal(body(trace_calls(fun))[[3]], body(fun))
})
test_that("one-line functions with braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) {
    x + 1
  }

  expect_equal(as.character(body(trace_calls(fun))[[2]][[2]][[1]])[3], "count")

  expect_equal(body(trace_calls(fun))[[2]][[3]], body(fun)[[2]])
})
