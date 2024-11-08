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
