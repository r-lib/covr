context("coverage of parallel code")


test_that("mcparallel without the fix", {
  cov <- package_coverage("TestParallel", type = "test")
  # only the non parallel code is covered
  expect_equal(floor(percent_coverage(cov)), 33)
})


test_that("mcparallel with the fix", {
    cov <- package_coverage("TestParallel", type = "test",
      fix_parallel_mcexit = TRUE)
    # only the non parallel code is covered
    expect_equal(percent_coverage(cov), 100)
})