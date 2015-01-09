test_that("compiled function simple works", {
  expect_equal(simple(1), 1)
  expect_equal(simple(2), 1)
  expect_equal(simple(3), 1)
  expect_equal(simple(-1), -1)
})
