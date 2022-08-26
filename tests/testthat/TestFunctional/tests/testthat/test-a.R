test_that("regular function `a` works as expected", {
  expect_equal(a(), TRUE)
  expect_equal(b(), FALSE)
})
