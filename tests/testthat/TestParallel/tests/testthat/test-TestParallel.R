test_that("test_me works", {
  library(parallel)
  mccollect(mcparallel(
    expect_equal(test_me(2, 2), 4)
  ))
})
