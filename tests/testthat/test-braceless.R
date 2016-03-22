context("braceless")

test_that("if", {
  f <- function(x) {
    if (x)
      TRUE
    else
      FALSE
  }

  expect_equal(percent_coverage(function_coverage(f, f(TRUE))), 50)
  expect_equal(percent_coverage(function_coverage(f, f(FALSE))), 75)
  expect_equal(percent_coverage(function_coverage(f, { f(TRUE); f(FALSE) })), 100)
})

test_that("if complex", {
  f <- function(x) {
    if (x)
      x <- TRUE
    else
      x <- FALSE
  }

  expect_equal(percent_coverage(function_coverage(f, f(TRUE))), 50)
  expect_equal(percent_coverage(function_coverage(f, f(FALSE))), 75)
  expect_equal(percent_coverage(function_coverage(f, { f(TRUE); f(FALSE) })), 100)
})
