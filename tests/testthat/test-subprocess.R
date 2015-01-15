context("subprocess")
test_that("subprocess creates new objects in the local environment", {
  subprocess(a <- 1)
  expect_equal(a, 1)
})
test_that("subprocess uses objects in the local environment", {
  a <- 1
  subprocess(b <- a + 2)
  expect_equal(b, 3)
})
