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
  stderr <- capture.output(
    stdout <- capture.output(
      cov <- package_coverage(
        "TestS4",
        type = "none",
        code = c("a(1)", "message('from code')"),
        show_code_output = TRUE
      )
    ),
    type = "message"
  )
  expect_equal(
    stdout,
    c("> library('TestS4')", "> a(1)", "[1] 1", "> message('from code')", "> ")
  )
  expect_equal(stderr, "from code")
  expect_gt(percent_coverage(cov), 0.00)
})

test_that("package_coverage reports failures of code shown while it runs", {
  stderr <- capture.output(
    stdout <- capture.output(
      err <- expect_error(
        package_coverage(
          "TestS4",
          type = "none",
          code = "stop('boom')",
          show_code_output = TRUE
        ),
        class = "covr_error"
      )
    ),
    type = "message"
  )
  expect_equal(stdout, c("> library('TestS4')", "> stop('boom')"))
  expect_equal(stderr, c("Error: boom", "Execution halted"))
  expect_contains(err$output, c("> stop('boom')", "Error: boom"))
})

test_that("package_coverage reports killed code shown while it runs", {
  # Killing the process with SIGKILL relies on POSIX signals
  skip_on_os("windows")
  stderr <- capture.output(
    stdout <- capture.output(
      err <- expect_error(
        package_coverage(
          "TestS4",
          type = "none",
          code = "tools::pskill(Sys.getpid(), tools::SIGKILL)",
          show_code_output = TRUE
        ),
        class = "covr_error"
      )
    ),
    type = "message"
  )
  expect_match(stderr, "SIGNAL", all = FALSE)
  expect_match(err$output, "SIGNAL", all = FALSE)
})
