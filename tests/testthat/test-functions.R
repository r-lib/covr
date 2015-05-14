context("evaluated functions")
test_that("function_coverage generates output", {
  eval(parse(text =
"fun <- function(x) {
  if (isTRUE(x)) {
    1
  } else {
    2
  }
}"))

  t1 <- function_coverage("fun", env = environment())
  expect_equal(length(t1), 3)

  expect_equal(length(exclude(t1)), 3)

  expect_equal(length(exclude(t1, "<text>")), 0)

  expect_equal(length(exclude(t1, list("<text>" = 3))), 2)
})
