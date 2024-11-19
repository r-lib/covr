test_that("gitlab", {
  cov <- package_coverage("TestS4")

  on.exit(unlink("TestS4/public", recursive = TRUE), add = TRUE)

  expect_error(gitlab(coverage = cov), NA)

  expect_true(file.exists("TestS4/public/coverage.html"))
})
