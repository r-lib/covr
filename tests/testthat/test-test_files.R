test_that("package_coverage() only includes the test files with include_tests = TRUE", {
  cov <- package_coverage("TestTestFiles")

  expect_equal(unique(display_name(cov)), "R/add.R")
})

test_that("package_coverage(include_tests = TRUE) measures the coverage of the test files", {
  # Run `expect_snapshot()`, to check that its code is not instrumented
  withr::local_envvar(NOT_CRAN = "true")
  # A file the tests read, which must not be instrumented
  withr::local_options(covr.covrignore = "covrignore")
  cov <- package_coverage("TestTestFiles", include_tests = TRUE)
  lines <- tally_coverage(cov, by = "line")
  line <- function(file, line) {
    lines[lines$filename == file & lines$line == line, c("functions", "value")]
  }

  expect_setequal(
    lines$filename,
    c(
      "R/add.R",
      "tests/plain.R",
      "tests/testthat.R",
      "tests/testthat/helper-utils.R",
      "tests/testthat/test-add.R"
    )
  )
  expect_equal(
    line("tests/testthat/helper-utils.R", 2),
    data.frame(functions = "used_helper", value = 1),
    ignore_attr = TRUE
  )
  expect_equal(
    line("tests/testthat/helper-utils.R", 6),
    data.frame(functions = "unused_helper", value = 0),
    ignore_attr = TRUE
  )
  expect_equal(line("tests/testthat/test-add.R", 7)$value, 1)
  expect_equal(
    line("tests/testthat/test-add.R", 8),
    data.frame(functions = "(top level)", value = 0),
    ignore_attr = TRUE
  )
  expect_equal(
    line("tests/plain.R", 4),
    data.frame(functions = "(top level)", value = 0),
    ignore_attr = TRUE
  )
  expect_equal(
    line("tests/plain.R", 6),
    data.frame(functions = "(top level)", value = 1),
    ignore_attr = TRUE
  )
  expect_equal(line("tests/testthat.R", 4)$value, 1)
})
