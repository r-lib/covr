context("Test")
test_that("compiled function simple works", {
  expect_equal(simple(1), 1)
  expect_equal(simple(2), 1)
  expect_equal(simple(3), 1)
  expect_equal(simple(-1), -1)
})

test_that("compiled function simple2 works", {
  expect_equal(simple2(1), 1)
  expect_equal(simple2(2), 1)
  expect_equal(simple2(3), 1)
  expect_equal(simple2(-1), -1)
})
