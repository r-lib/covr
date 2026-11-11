test_that("it works on Vectorized functions", {
  s1 <- local_r_file(c(
    "scalar_func <- function(x,y) {",
    "  z <- x + y",
    "}",
    "",
    'vector_func <- Vectorize(scalar_func,vectorize.args=c("x","y"),SIMPLIFY=TRUE)'
  ))
  t1 <- local_r_file("vector_func(1:10, 2)")
  cov <- file_coverage(s1, t1)
  cov_d <- as.data.frame(cov)

  expect_equal(cov_d$functions, "vector_func")
  expect_equal(cov_d$value, 10)
})

test_that("with_coverage() restores the function a Vectorize wrapper calls", {
  src <- withr::local_tempfile(
    fileext = ".R",
    lines = c(
      "vector_func <- Vectorize(function(x, y) {",
      "  z <- x + y",
      "}, vectorize.args = c('x', 'y'))"
    )
  )
  env <- new.env()
  sys.source(src, envir = env, keep.source = TRUE)
  inner <- environment(env$vector_func)$FUN
  original <- body(inner)

  cov <- with_coverage(env$vector_func(1:3, 1), env = env)
  expect_equal(as.data.frame(cov)$value, 3)
  expect_identical(environment(env$vector_func)$FUN, inner)
  expect_identical(body(inner), original)

  cov <- with_coverage(env$vector_func(1:5, 1), env = env)
  expect_equal(as.data.frame(cov)$value, 5)
  expect_identical(body(inner), original)
})

test_that("functions are not Vectorize wrappers because of inherited bindings", {
  parent <- new.env()
  parent$FUN <- function(x) x
  parent$vectorize.args <- "x"
  fun <- function(x) x + 1
  environment(fun) <- new.env(parent = parent)

  expect_false(is_vectorized(fun))
  expect_null(wrapped_function(fun))
  expect_true(is_vectorized(Vectorize(function(x) x)))
  expect_false(is_vectorized(sum))
})
