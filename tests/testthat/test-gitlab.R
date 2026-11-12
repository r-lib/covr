test_that("gitlab writes the report in the package directory", {
  path <- local_gitlab_package()
  cov <- package_coverage(path)

  expect_no_error(res <- gitlab(coverage = cov))

  report <- file.path(normalizePath(path), "public", "coverage.html")
  expect_true(file.exists(report))
  expect_equal(normalize_path(res), normalize_path(report))
})

test_that("gitlab's file is relative to the package directory", {
  path <- local_gitlab_package()
  cov <- package_coverage(path)

  # Not the working directory
  withr::local_dir(withr::local_tempdir())
  gitlab(coverage = cov, file = "docs/report/index.html")
  expect_true(file.exists(file.path(path, "docs", "report", "index.html")))
  expect_false(dir.exists("docs"))
})

test_that("gitlab calls package_coverage() without coverage and prints it unless quiet", {
  cov <- package_coverage(local_gitlab_package())
  args <- NULL
  local_mocked_bindings(
    package_coverage = function(...) {
      args <<- list(...)
      cov
    }
  )

  expect_silent(gitlab(path = "TestS4"))
  expect_equal(args, list(quiet = TRUE, path = "TestS4"))

  expect_snapshot(gitlab(path = "TestS4", quiet = FALSE))
  expect_equal(args, list(quiet = FALSE, path = "TestS4"))
})
