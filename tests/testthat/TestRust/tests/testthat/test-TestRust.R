test_that("rust_sign works", {
  expect_equal(rust_sign(2), 1)
  expect_equal(rust_sign(5), 1)
  expect_equal(rust_sign(-3), -1)
})
