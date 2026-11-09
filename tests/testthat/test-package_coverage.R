test_that("package_coverage returns an error if the path does not exist", {
  expect_error(package_coverage("blah"))
})

test_that("package_coverage returns an error if the type is incorrect", {
  expect_error(
    package_coverage("TestPrint", type = "blah"),
    "'arg' should be one of"
  )

  expect_error(
    package_coverage("TestPrint", type = c("blah", "test")),
    "'arg' should be one of"
  )
})

test_that("package_coverage requires 'all' and 'none' to be the only type", {
  expect_snapshot(error = TRUE, {
    package_coverage("TestPrint", type = c("all", "tests"))
    package_coverage("TestPrint", type = c("none", "tests"))
  })
})

test_that("package_coverage(combine_types = FALSE) works with local variables", {
  f <- function() {
    pkg <- test_path("TestSummary")
    package_coverage(pkg, type = c("tests", "examples"), combine_types = FALSE)
  }
  cov <- f()
  expect_s3_class(cov, "coverages")
  expect_named(cov, c("tests", "examples"))
  expect_equal(attr(cov$examples, "type"), "examples")
})

test_that("package_coverage errors if the package can't be installed", {
  pkg <- withr::local_tempdir()
  dir.create(file.path(pkg, "R"))
  writeLines(
    c(
      "Package: TestBroken",
      "Version: 0.0.1",
      "Title: Broken",
      "Description: Does not install.",
      "License: GPL-3"
    ),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("x <- (", file.path(pkg, "R", "broken.R"))

  expect_error(package_coverage(pkg, type = "none"), "Can't install TestBroken")
})

test_that("package_coverage reports errors in `code` with a covr_error", {
  expect_error(
    package_coverage("TestS4", type = "none", code = "stop('boom')"),
    "boom",
    class = "covr_error"
  )
})

test_that("package_coverage(clean = FALSE) keeps the installed library", {
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)

  cov <- package_coverage(
    "TestS4",
    type = "none",
    clean = FALSE,
    install_path = install_path
  )

  expect_equal(
    normalize_path(attr(cov, "library")),
    normalize_path(install_path)
  )
  expect_contains(list.files(install_path), "TestS4")
})

test_that("package_coverage can return just tests and vignettes", {
  cov <- package_coverage(
    "TestPrint",
    type = c("tests", "vignettes"),
    combine_types = FALSE
  )

  expect_equal(names(cov), c("tests", "vignettes"))
})

test_that("package_coverage with type == 'all' returns test, vignette and example coverage", {
  cov <- package_coverage("TestPrint", type = "all", combine_types = FALSE)

  expect_equal(names(cov), c("tests", "vignettes", "examples"))
})

test_that("package_coverage with type == 'none' runs no test code", {
  cov <- package_coverage("TestS4", type = "none")

  expect_equal(percent_coverage(cov), 0.00)
})

test_that("package_coverage runs additional test code", {
  cov <- package_coverage("TestS4", type = "none", code = c("a(1)", "a(2)"))

  expect_gt(percent_coverage(cov), 0.00)
})

test_that("package_coverage can show the output of code while it runs", {
  out <- capture_streams(
    cov <- package_coverage(
      "TestS4",
      type = "none",
      code = c("a(1)", "message('from code')"),
      show_code_output = TRUE
    )
  )
  expect_equal(
    out$stdout,
    c("> library('TestS4')", "> a(1)", "[1] 1", "> message('from code')", "> ")
  )
  # Loading the package may print startup messages first, e.g. about
  # overwritten S3 methods when covr itself is being measured.
  expect_equal(tail(out$stderr, 1), "from code")
  expect_gt(percent_coverage(cov), 0.00)
})

test_that("package_coverage reports failures of code shown while it runs", {
  out <- capture_streams(
    err <- expect_error(
      package_coverage(
        "TestS4",
        type = "none",
        code = "stop('boom')",
        show_code_output = TRUE
      ),
      class = "covr_error"
    )
  )
  expect_equal(out$stdout, c("> library('TestS4')", "> stop('boom')"))
  expect_equal(tail(out$stderr, 2), c("Error: boom", "Execution halted"))
  expect_contains(err$output, c("> stop('boom')", "Error: boom"))
})

test_that("package_coverage reports killed code shown while it runs", {
  # Killing the process with SIGKILL relies on POSIX signals
  skip_on_os("windows")
  out <- capture_streams(
    err <- expect_error(
      package_coverage(
        "TestS4",
        type = "none",
        code = "tools::pskill(Sys.getpid(), tools::SIGKILL)",
        show_code_output = TRUE
      ),
      class = "covr_error"
    )
  )
  expect_match(out$stderr, "SIGNAL", all = FALSE)
  expect_match(err$output, "SIGNAL", all = FALSE)
})
