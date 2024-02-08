box::use(
  testthat[test_that, expect_equal, expect_s3_class]
)

box::use(
  app/modules/moduleR6
)

test_that("TestR6 class can be instantiated", {
  skip_if(is_r_devel())
  t1 <- moduleR6$TestR6$new() # nolint

  expect_s3_class(t1, "R6")
  expect_s3_class(t1, "TestR6")
  })

test_that("TestR6 Methods can be evaluated", {
  skip_if(is_r_devel())
  t1 <- moduleR6$TestR6$new() # nolint

  expect_equal(t1$show(), 4)
  expect_equal(print(t1$print2()), 3)
})
