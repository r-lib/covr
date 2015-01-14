context("environment_coverage")
test_that("environment_coverage calls environment_coverage_", {

  # this is pretty silly, make more useful later
  with_mock(environment_coverage_ = function(...) TRUE,
    expect_true(environment_coverage(NULL))
    )
})

context("package_coverage")
test_that("package_coverage returns NULL if the path does not exist", {
  expect_null(package_coverage("blah"))
})

context("function_coverage")
test_that("function_coverage", {

  options(keep.source = TRUE)
  f <- function(x) {
    x + 1
  }
  expect_equal(as.numeric(function_coverage("f", env = environment(f))), 0)

  expect_equal(as.numeric(function_coverage("f", env = environment(f), f(1))), 1)

  expect_equal(as.numeric(function_coverage("f", env = environment(f), f(1), f(1))), 2)
})

test_that("function_coverage identity function", {
  options(keep.source = TRUE)

  fun <- function(x) {
      x
  }

  cov_num <- function(...) {
    as.numeric(function_coverage("fun", env = environment(fun), ...))
  }

  expect_equal(cov_num(), 0)
  expect_equal(cov_num(fun(1)), 1)

})

test_that("function_coverage return last expr", {

  options(keep.source = TRUE)
  fun <- function() {
    x <- 1
    x
  }

  cov_fun <- function(...) {
    function_coverage("fun", env = environment(fun), ...)
  }

  expect_equal(as.numeric(cov_fun()), c(0L, 0L))
  expect_equal(as.numeric(cov_fun(fun())), c(1L, 1L))
})

test_that("duplicated first_line", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old))

  fun <- function() {
      res <- lapply(1:2, function(x) { x + 1 })
  }
  cov <- function_coverage("fun", env = environment(fun))
  first_lines <- as.data.frame(cov)$first_line
  expect_equal(length(first_lines), 2)
  expect_equal(first_lines[1], first_lines[2])
})

context("trace_calls")
test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})
