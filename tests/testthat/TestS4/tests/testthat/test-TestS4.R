test_that("regular function `a` works as expected", {
  expect_equal(a(1), 1)
  expect_equal(a(2), 2)
  expect_equal(a(3), 2)
  expect_equal(a(4), 2)
  expect_equal(a(0), 1)
})

test_that("TestS4 class can be instantiated", {
  t1 <- TestS4() # nolint
})

test_that("TestS4 Methods can be evaluated", {
  t1 <- TestS4() # nolint

  show(t1)
  print(print2(t1))

  print(print2(t1, "hi"))
})
