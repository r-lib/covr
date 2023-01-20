box::use(
  testthat[test_that, expect_equal]
)

box::use(
  app/modules/module
)

impl <- attr(module, "namespace")

test_that("regular function `a` works as expected", {
  expect_equal(module$a(1), 1)
  expect_equal(module$a(2), 2)
  expect_equal(module$a(3), 2)
  expect_equal(module$a(4), 2)
  expect_equal(module$a(0), 1)
})

test_that("private function works as expected", {
  expect_equal(impl$private_function(2), 4)
  expect_equal(impl$private_function(3), 9)
  expect_equal(impl$private_function(4), 16)
})
