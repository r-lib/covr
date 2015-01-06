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
context("trace_calls")
test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})
