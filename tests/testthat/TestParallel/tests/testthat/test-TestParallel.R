test_that("test_me works", {
  library(parallel)

  mccollect(mcparallel(
    expect_equal(test1(2, 2), 4)
  ))

  mccollect(mcparallel(
      expect_equal(test2(2, 2), 4)
  ))

  expect_equal(test3(2, 2), 0)
})
