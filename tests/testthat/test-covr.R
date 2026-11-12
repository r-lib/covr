test_that("in_covr() reflects R_COVR", {
  withr::local_envvar(R_COVR = "true")
  expect_equal(in_covr(), TRUE)

  withr::local_envvar(R_COVR = NA)
  expect_equal(in_covr(), FALSE)
})
