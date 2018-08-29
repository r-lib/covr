context("gitlab")

test_that("gitlab", {
  cov = package_coverage("TestS4")
  expect_output(gitlab(coverage = cov), "Code coverage: 100.00 %")
  expect_true(file.exists("TestS4/public/coverage.html"))
  if (dir.exists("TestS4/public"))
    unlink("TestS4/public", recursive = TRUE, force = TRUE)
})
