box::use(
  testthat[test_that, expect_equal]
)

box::use(
  app/modules/module
)

test_that("regular function `a` works as expected", {
  expect_equal(module$a(1), 1)
  expect_equal(module$a(2), 2)
  expect_equal(module$a(3), 2)
  expect_equal(module$a(4), 2)
  expect_equal(module$a(0), 1)
})
