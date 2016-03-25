context("braceless")

test_that("if", {
  f <- function(x) {
    if (FALSE)
      FALSE # never covered, used as anchor
    if (x)
      TRUE
    else
      FALSE
  }

  expect_equal(diff(zero_coverage(function_coverage(f, f(TRUE)))$line),
               c(3, 1))
  expect_equal(diff(zero_coverage(function_coverage(f, f(FALSE)))$line), 2)
  expect_equal(length(zero_coverage(function_coverage(f, { f(TRUE); f(FALSE) }))$line),
               1)
})

test_that("if complex", {
  f <- function(x) {
    if (FALSE)
      FALSE # never covered, used as anchor
    if (x)
      x <- TRUE
    else
      x <- FALSE
  }

  expect_equal(diff(zero_coverage(function_coverage(f, f(TRUE)))$line),
               c(3, 1))
  expect_equal(diff(zero_coverage(function_coverage(f, f(FALSE)))$line),
               2)
  expect_equal(length(zero_coverage(function_coverage(f, { f(TRUE); f(FALSE) }))$line),
               1)
})

test_that("switch", {
  f <<- function(x) {
    switch(x,
      a = 1,
      b = 2,
      c = d <- 1
    )
  }

  expect_equal(length(zero_coverage(function_coverage(f, { f("a"); f("b") }))$line),
    1)
  expect_equal(length(zero_coverage(function_coverage(f, { f("a"); f("c") }))$line),
    1)
  expect_equal(diff(zero_coverage(function_coverage(f, { f("a"); f("d") }))$line),
    1)
})
