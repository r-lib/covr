box::use(
  testthat[test_that, expect_equal]
)

box::use(
  x = app/modules/module
)

test_that("attached regular function `a` works as expected", {
  expect_equal(x$a(1), 1)
  expect_equal(x$a(2), 2)
  expect_equal(x$a(3), 2)
  expect_equal(x$a(4), 2)
  expect_equal(x$a(0), 1)
})
