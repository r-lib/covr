test_that("compiled function simple works", {
  expect_equal(simple(1), 1)
  expect_equal(simple(2), 1)
  expect_equal(simple(3), 1)
  expect_equal(simple(-1), -1)
})

test_that("compiled function simple3 works", {
  expect_equal(simple3(1), 1)
  expect_equal(simple3(2), 1)
})

test_that("compiled function simple4 works", {
  expect_equal(simple4(3L), 1L)
  expect_equal(simple4(-1L), -1L)
})

test_that("compiled function simple5 works", {
  # positive, negative values are tested in if() conditions,
  #   but both evaluate to '0' --> branch code is not executed.
  expect_false(simple5(0))
})
