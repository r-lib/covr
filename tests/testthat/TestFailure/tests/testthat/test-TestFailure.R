test_that("covered works", {
  expect_equal(covered(1), 2)
})

test_that("this test fails", {
  expect_equal(covered(1), 3)
})
