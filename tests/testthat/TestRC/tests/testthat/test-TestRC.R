test_that("regular function `a` works as expected", {
  expect_equal(a(1), 1)
  expect_equal(a(2), 2)
  expect_equal(a(3), 2)
  expect_equal(a(4), 2)
  expect_equal(a(0), 1)
})

test_that("TestRC class can be instantiated", {
  t1 <- TestRC() # nolint
})

test_that("TestRC Methods can be evaluated", {
  t1 <- TestRC() # nolint

  t1$show()
  print(t1$print2())
})
