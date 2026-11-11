test_that("to_cobertura() warns once and writes the same file as cobertura()", {
  local_deprecation_warnings()
  without_timestamp <- function(file) {
    sub(' timestamp="[^"]*"', "", readLines(file))
  }
  cov <- code_coverage("f <- function(x) if (x) 1 else 2", "f(TRUE)")
  new <- withr::local_tempfile(fileext = ".xml")
  old <- withr::local_tempfile(fileext = ".xml")

  cobertura(cov, filename = new)
  expect_snapshot(to_cobertura(cov, filename = old))
  expect_equal(without_timestamp(old), without_timestamp(new))

  expect_no_warning(to_cobertura(cov, filename = old))
})

test_that("to_sonarqube() warns once and writes the same file as sonarqube()", {
  local_deprecation_warnings()
  cov <- code_coverage("f <- function(x) if (x) 1 else 2", "f(TRUE)")
  new <- withr::local_tempfile(fileext = ".xml")
  old <- withr::local_tempfile(fileext = ".xml")

  sonarqube(cov, filename = new, path_prefix = "pkg")
  expect_snapshot(to_sonarqube(cov, filename = old, path_prefix = "pkg"))
  expect_equal(readLines(old), readLines(new))

  expect_no_warning(to_sonarqube(cov, filename = old))
})
