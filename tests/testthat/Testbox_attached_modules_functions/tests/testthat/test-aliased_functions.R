box::use(
  testthat[test_that, expect_equal]
)

box::use(
  app/modules/module[x = a]
)

test_that("attached regular function `a` works as expected", {
  expect_equal(x(1), 1)
  expect_equal(x(2), 2)
  expect_equal(x(3), 2)
  expect_equal(x(4), 2)
  expect_equal(x(0), 1)
})
