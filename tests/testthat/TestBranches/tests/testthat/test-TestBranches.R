test_that("branches", {
  # Run in a forked process where possible, so its branches are saved by the
  # patched `parallel::mcexit()`. The fork comes first, as a forked process
  # also saves the counts its parent had when it was forked.
  if (.Platform$OS.type == "windows") {
    expect_equal(forked(TRUE), "yes")
  } else {
    res <- parallel::mccollect(parallel::mcparallel(forked(TRUE)))
    expect_equal(res[[1]], "yes")
  }
  expect_equal(sign_of(1), "positive")
  expect_equal(sign_of(0), "zero")
  expect_equal(describe("a"), "early")
  expect_null(describe("q"))
})
