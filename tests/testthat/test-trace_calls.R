test_that("one-line functions are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x + 1

  expect_equal(as.character(body(trace_calls(fun))[[3]][[2]][[1]]),
      c(":::", "covr", "count"))

  fun <- function() 1

  expect_equal(as.character(body(trace_calls(fun))[[3]][[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[3]][[3]], body(fun))
})
test_that("one-line functions with no calls are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) x

  expect_equal(as.character(body(trace_calls(fun))[[3]][[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[3]][[3]], body(fun))
})
test_that("one-line functions with braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function(x) {
    x + 1
  }

  expect_equal(as.character(body(trace_calls(fun))[[2]][[3]][[2]][[1]]),
      c(":::", "covr", "count"))

  expect_equal(body(trace_calls(fun))[[2]][[3]][[3]], body(fun)[[2]])
})

test_that("one-line functions with no calls and braces are traced correctly", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
    1
  }

  e2 <- body(trace_calls(fun))[[2]][[3]]
  expect_true(length(e2) > 1 &&
              identical(as.character(e2[[2]][[1]]), c(":::", "covr", "count")))

  fun <- function(x) {
    x
  }

  e2 <- body(trace_calls(fun))[[2]][[3]]

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
  e3 <- body[[3]][[3]]
  expect_true(length(e3) > 1 &&
    identical(as.character(e3[[2]][[1]]), c(":::", "covr", "count")))

})

test_that("functions with NULL bodies are traced correctly", {
  old <- options(keep.source = TRUE)
  on.exit(options(old))

  fun <- function() NULL

  expect_null(trace_calls(fun)())
})

test_that("functions with curly curly syntax are traced correctly", {
  my_capture <- function(x) {
    rlang::expr({{ x }})
  }
  expect_equal(my_capture(5 == 1), rlang::quo(5 == 1))

  # behavior not changed by covr
  my_capture2 <- trace_calls(my_capture)
  expect_equal(my_capture2(5 == 1), rlang::quo(5 == 1))

  # outer code traced traced with ({  })
  expect_equal(as.character(body(my_capture2)[[2]][[1]]), "if")
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[1]]), "{")
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[2]][[1]]), c(":::", "covr", "count"))

  # no trace in the internal {{  }}
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[3]][[2]][[1]]), "{")
  expect_equal(as.character(body(my_capture2)[[2]][[3]][[3]][[2]][[2]][[1]]), "{")
})


test_that("functions that rely on implicit invisibility work the same", {
  f <- function(x) {
    x <- 1
  }

  f2 <- trace_calls(f)

  expect_equal(withVisible(f2(1)), withVisible(f(1)))

  f3 <- function(x) {
    x + 1
  }

  f4 <- trace_calls(f3)

  expect_equal(withVisible(f3(1)), withVisible(f4(1)))
})


test_that("functions that use S3 dispatch work", {
  cov <- code_coverage( source_code = '
foo <- function(x) {
  UseMethod("foo")
}

foo.bar <- function(x) { x[[1]] + 1 }

bar <- function(x) {
  structure(list(x), class = "bar")
}
', test_code = '
stopifnot(foo(bar(1)) == 2)
')
  expect_equal(percent_coverage(cov), 100)
})
