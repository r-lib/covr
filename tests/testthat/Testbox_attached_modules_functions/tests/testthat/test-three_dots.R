box::use(
  testthat[test_that, expect_equal]
)

box::use(
  app/modules/module[...]
)

test_that("attached regular function `a` works as expected", {
  expect_equal(a(1), 1)
  expect_equal(a(2), 2)
  expect_equal(a(3), 2)
  expect_equal(a(4), 2)
  expect_equal(a(0), 1)
})

test_that("attached regular function `b` works as expected", {
  expect_equal(b(1), 2)
  expect_equal(b(2), 4)
  expect_equal(b(3), 6)
})
