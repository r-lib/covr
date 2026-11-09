test_that("gitlab", {
  cov <- package_coverage("TestS4")

  on.exit(unlink("TestS4/public", recursive = TRUE), add = TRUE)

  expect_error(gitlab(coverage = cov), NA)

  expect_true(file.exists("TestS4/public/coverage.html"))
})

test_that("gitlab calls package_coverage() without coverage and prints it unless quiet", {
  cov <- package_coverage("TestS4")
  args <- NULL
  local_mocked_bindings(
    package_coverage = function(...) {
      args <<- list(...)
      cov
    }
  )
  on.exit(unlink("TestS4/public", recursive = TRUE), add = TRUE)

  expect_silent(gitlab(path = "TestS4"))
  expect_equal(args, list(quiet = TRUE, path = "TestS4"))

  expect_snapshot(gitlab(path = "TestS4", quiet = FALSE))
  expect_equal(args, list(quiet = FALSE, path = "TestS4"))
})
