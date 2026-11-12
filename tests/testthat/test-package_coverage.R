test_that("package_coverage returns an error if the path does not exist", {
  expect_snapshot(package_coverage("blah"), error = TRUE)
})

test_that("package_coverage returns an error if the type is incorrect", {
  expect_snapshot(package_coverage("TestPrint", type = "blah"), error = TRUE)
  expect_snapshot(
    package_coverage("TestPrint", type = c("blah", "test")),
    error = TRUE
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

  err <- tryCatch(package_coverage(pkg, type = "none"), error = identity)
  expect_match(conditionMessage(err), "Can't install TestBroken")
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

test_that("package_coverage keeps install_path only when coverage fails", {
  install_path <- withr::local_tempfile(pattern = "R_LIBS")
  expect_error(
    package_coverage(test_path("TestFailure"), install_path = install_path),
    class = "covr_error"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")

  install_path <- withr::local_tempfile(pattern = "R_LIBS")
  package_coverage(test_path("TestSummary"), install_path = install_path)
  expect_false(dir.exists(install_path))
})

test_that("package_coverage passes outDir to testInstalledPackage", {
  out_dir <- file.path(withr::local_tempdir(), "out")
  package_coverage(test_path("TestSummary"), outDir = out_dir)
  expect_contains(
    list.files(out_dir, recursive = TRUE),
    "TestSummary-tests/testthat.Rout"
  )
})

test_that("package_coverage gives the reason the package can't be installed", {
  pkg <- withr::local_tempdir()
  writeLines(
    c("Package: Broken", "Version: 0.1"),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("", file.path(pkg, "NAMESPACE"))
  dir.create(file.path(pkg, "R"))
  writeLines("f <- function( {", file.path(pkg, "R", "f.R"))
  err <- tryCatch(package_coverage(pkg), error = identity)
  expect_match(conditionMessage(err), "Can't install")
  expect_match(conditionMessage(err), "unexpected")
})

test_that("package_coverage shows messages and warnings unless quiet", {
  local_mocked_bindings(
    run_commands = function(...) {
      message("a message")
      warning("a warning")
    }
  )
  expect_no_message(expect_no_warning(
    package_coverage(test_path("TestS4"), type = "none", quiet = TRUE)
  ))
  expect_snapshot(
    . <- package_coverage(test_path("TestS4"), type = "none", quiet = FALSE)
  )
})

test_that("install_package shows the installation output unless quiet", {
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestS4"))
  install_package(pkg, lib, character(), quiet = FALSE)
  expect_contains(list.files(lib), "TestS4")
})

test_that("copy_installed_package gives the reasons the copy failed", {
  pkg <- local_installed_package("TestSummary", "--with-keep.source")
  err <- tryCatch(
    copy_installed_package(
      as_package(pkg),
      file.path(withr::local_tempdir(), "lib")
    ),
    error = conditionMessage
  )
  expect_match(err, "Can't copy the installed package TestSummary")
  # the reasons are the warnings of `file.copy()`, not the fallback
  expect_no_match(err, "`file.copy()` failed.", fixed = TRUE)
})

test_that("copy_installed_package fails if the copy has no DESCRIPTION", {
  pkg <- list(package = "pkg", path = file.path(withr::local_tempdir(), "pkg"))
  dir.create(pkg$path)
  err <- tryCatch(
    copy_installed_package(pkg, withr::local_tempdir()),
    error = conditionMessage
  )
  expect_match(err, "`file.copy()` failed.", fixed = TRUE)
})

test_that("add_hooks() errors if the loader script doesn't read the package", {
  lib <- withr::local_tempdir()
  dir.create(file.path(lib, "pkg", "R"), recursive = TRUE)
  writeLines("loadNamespace('pkg')", file.path(lib, "pkg", "R", "pkg"))

  expect_snapshot(
    add_hooks("pkg", lib, counters_file = "counters.rds"),
    error = TRUE
  )
})

test_that("run_vignettes reports failures to build the vignettes", {
  lib <- withr::local_tempdir()
  pkg <- list(package = "TestMissing", path = file.path(lib, "missing"))
  expect_error(run_vignettes(pkg, lib), class = "covr_error")
})

test_that("package_coverage measures installed packages (#638)", {
  pkg <- local_installed_package(
    "TestSummary",
    c("--install-tests", "--with-keep.source")
  )
  df <- as.data.frame(package_coverage(pkg))
  expect_equal(unique(df$filename), "R/TestSummary.R")
  expect_equal(df$first_line, c(5, 6, 8, 13))
  expect_equal(df$value, c(1, 1, 0, 0))
})

test_that("package_coverage needs tests and srcrefs of installed packages", {
  install_path <- file.path(withr::local_tempdir(), "lib")
  pkg <- local_installed_package("TestSummary", "--with-keep.source")
  expect_snapshot(
    package_coverage(pkg, install_path = install_path),
    error = TRUE
  )
  pkg <- local_installed_package(
    "TestSummary",
    c("--install-tests", "--without-keep.source")
  )
  expect_snapshot(
    package_coverage(pkg, install_path = install_path),
    error = TRUE
  )
})

test_that("package_coverage errors carry the full testthat output", {
  err <- expect_error(
    package_coverage(test_path("TestFailure")),
    class = "covr_error"
  )
  expect_true(file.exists(err$file))
  expect_match(paste(err$output, collapse = "\n"), "this test fails")
})

test_that("package_coverage errors on test failures by default", {
  expect_error(
    package_coverage(test_path("TestFailure")),
    "this test fails",
    class = "covr_error"
  )
})

test_that("covr.allow_failures returns coverage despite test failures", {
  withr::local_options(covr.allow_failures = TRUE)
  install_path <- withr::local_tempfile(pattern = "R_LIBS")
  expect_warning(
    cov <- package_coverage(
      test_path("TestFailure"),
      install_path = install_path
    ),
    "this test fails",
    class = "covr_warning"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["covered"]], 0)
  expect_equal(values[["not_covered"]], 0)
})

test_that("package_coverage reports bad trace files", {
  code <- paste0(
    "writeBin(as.raw(1:5), file.path(",
    "Sys.getenv('COVERAGE_DIR', .libPaths()[1]), 'covr_trace_corrupt'))"
  )
  pkg <- test_path("TestSummary")

  expect_error(
    package_coverage(pkg, type = "none", code = code, quiet = TRUE),
    "covr_trace_corrupt",
    class = "covr_error"
  )

  expect_warning(
    cov <- package_coverage(
      pkg,
      type = "none",
      code = code,
      quiet = TRUE,
      allow_failures = TRUE
    ),
    "covr_trace_corrupt",
    class = "covr_warning"
  )
  expect_s3_class(cov, "coverage")
  expect_gt(length(cov), 0)
})

test_that("package_coverage warns about processes that did not save a trace", {
  # Killing the process with SIGKILL relies on POSIX signals
  skip_on_os("windows")

  rscript <- function(code) {
    paste0(
      "system2(file.path(R.home('bin'), 'Rscript'), ",
      "c('--vanilla', '-e', shQuote('library(TestSummary); ",
      code,
      "')))"
    )
  }
  code <- c(
    rscript("test_me(1, 2)"),
    rscript("dont_test_me(1, 2); tools::pskill(Sys.getpid(), tools::SIGKILL)")
  )

  expect_snapshot(
    cov <- package_coverage(
      test_path("TestSummary"),
      type = "none",
      code = code
    )
  )
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["test_me"]], 0)
  expect_equal(values[["dont_test_me"]], 0)
})

test_that("package_coverage works if the site libraries are removed (#560)", {
  # for `.libPaths(include.site = FALSE)`
  skip_if(getRversion() < "4.1.0")

  # As renv does when it activates its sandbox, e.g. if the package imports
  # renv in an renv project, where this session has no site libraries. Site
  # libraries of this session are kept, as they could have covr's dependencies.
  site <- normalizePath(.Library.site, winslash = "/")
  script <- withr::local_tempfile(
    fileext = ".R",
    lines = c(
      sprintf("keep <- %s", paste(deparse(site), collapse = "")),
      "site <- setdiff(normalizePath(.Library.site, winslash = '/'), keep)",
      ".libPaths(setdiff(.libPaths(), site), include.site = FALSE)",
      "library(TestSummary)",
      "test_me(1, 2)"
    )
  )
  code <- sprintf(
    "stopifnot(system2(file.path(R.home('bin'), 'Rscript'), c('--vanilla', shQuote(%s))) == 0)",
    deparse(normalizePath(script, winslash = "/"))
  )

  cov <- package_coverage(test_path("TestSummary"), type = "none", code = code)
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["test_me"]], 0)
})

test_that("R processes get only the site libraries of this session (#560)", {
  site_libraries <- function(site) {
    withr::local_envvar(R_LIBS_SITE = r_libs_site(site))
    system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "-e", shQuote("writeLines(.Library.site)")),
      stdout = TRUE
    )
  }

  expect_equal(site_libraries(character()), character())
  site <- normalize_path(withr::local_tempdir())
  expect_equal(normalize_path(site_libraries(site)), site)
})

test_that("package_coverage() requires a single string as relative_path", {
  expect_snapshot(
    package_coverage(test_path("TestS4"), relative_path = c("a", "b")),
    error = TRUE
  )
})
