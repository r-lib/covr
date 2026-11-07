test_that("nested functions can be called", {
  expect_equal(fun_list$a(1), 2)
  expect_equal(api(), 1)
})
