test_that("mcparallel without the fix", {
  skip_on_os("windows")

  cov <- withr::with_options(
    list(covr.fix_parallel_mcexit = FALSE),
    package_coverage("TestParallel", type = "test")
  )
  # only the non parallel code is covered
  expect_equal(floor(percent_coverage(cov)), 33)
})


test_that("mcparallel with the fix", {
  skip_on_os("windows")

  # using auto detection
  cov <- package_coverage(test_path("TestParallel"), type = "test")
  # only the non parallel code is covered
  expect_equal(percent_coverage(cov), 100)
})


test_that("mcparallel workers that load the package after forking do not warn", {
  skip_on_os("windows")

  # The commands load the package first, so unload it to make the worker load it
  code <- c(
    "unloadNamespace('TestParallel'); invisible(gc())",
    "stopifnot(!isNamespaceLoaded('TestParallel'))",
    "parallel::mccollect(parallel::mcparallel({",
    "  library(TestParallel); test1(1, 2)",
    "}))"
  )
  expect_no_condition(
    cov <- package_coverage(
      test_path("TestParallel"),
      type = "none",
      code = code
    ),
    class = "covr_unsaved_trace"
  )
  tally <- tally_coverage(cov)
  expect_gt(tally$value[tally$functions == "test1"], 0)
})


test_that("file_coverage() includes code run in forked processes", {
  skip_on_os("windows")
  src <- withr::local_tempfile(fileext = ".R")
  test <- withr::local_tempfile(fileext = ".R")
  writeLines(
    c(
      "a <- function(x) {",
      "  x + 1",
      "}",
      "b <- function(x) {",
      "  x * 2",
      "}"
    ),
    src
  )
  writeLines(
    c(
      "a(0)",
      "parallel::mclapply(1:4, a, mc.cores = 2)",
      "parallel::mccollect(parallel::mcparallel(b(1)))"
    ),
    test
  )

  # a(0) runs before forking, but is only counted once
  cov <- file_coverage(src, test)
  expect_equal(as.data.frame(cov)$value, c(5, 1))

  withr::local_options(covr.fix_parallel_mcexit = FALSE)
  cov <- file_coverage(src, test)
  expect_equal(as.data.frame(cov)$value, c(1, 0))
})


test_that("file_coverage() restores parallel's functions when code fails", {
  skip_on_os("windows")
  ns <- asNamespace("parallel")
  mcfork <- ns$mcfork
  mcexit <- ns$mcexit
  src <- withr::local_tempfile(fileext = ".R")
  test <- withr::local_tempfile(fileext = ".R")
  writeLines("a <- function(x) x", src)
  writeLines(
    c(
      "parallel::mclapply(1:2, a, mc.cores = 2)",
      paste0(
        "stop(structure(list(message = 'boom', call = NULL), ",
        "class = c('covr_test_error', 'error', 'condition')))"
      )
    ),
    test
  )

  expect_error(file_coverage(src, test), class = "covr_test_error")
  expect_identical(ns$mcfork, mcfork)
  expect_identical(ns$mcexit, mcexit)
})


test_that("uses_parallel", {
  pkg <- covr:::as_package("TestParallel")
  expect_true(covr:::uses_parallel(pkg))

  pkg <- covr:::as_package("TestSummary")
  expect_false(covr:::uses_parallel(pkg))
})


test_that("should_enable_parallel_mcexit_fix", {
  skip_on_os("windows")
  on.exit(
    {
      Sys.unsetenv('COVR_FIX_PARALLEL_MCEXIT')
      options(covr.fix_parallel_mcexit = NULL)
    },
    add = TRUE
  )

  grid <- expand.grid(
    var = c(NA, TRUE, FALSE),
    option = c(NA, TRUE, FALSE),
    pkg = c("TestParallel", "TestSummary"),
    stringsAsFactors = FALSE
  )

  grid$res <- with(
    grid,
    ifelse(
      !is.na(option),
      option,
      ifelse(!is.na(var), var, pkg == "TestParallel")
    )
  )

  .test_config <- function(var, option, pkgname) {
    if (is.na(var)) {
      Sys.unsetenv('COVR_FIX_PARALLEL_MCEXIT')
    } else {
      Sys.setenv(COVR_FIX_PARALLEL_MCEXIT = var)
    }

    if (is.na(option)) {
      options(covr.fix_parallel_mcexit = NULL)
    } else {
      options(covr.fix_parallel_mcexit = option)
    }

    pkg <- covr:::as_package(pkgname)
    covr:::should_enable_parallel_mcexit_fix(pkg)
  }

  res <- with(
    grid,
    vapply(
      1:nrow(grid),
      function(i) .test_config(var[i], option[i], pkg[i]),
      TRUE
    )
  )

  expect_identical(res, grid$res)
})

test_that("should_enable_parallel_mcexit_fix accepts the spellings of logicals", {
  skip_on_os("windows")
  withr::local_options(covr.fix_parallel_mcexit = NULL)
  pkg <- as_package(test_path("TestSummary"))
  for (value in c("true", "T", "yes", "1")) {
    withr::local_envvar(COVR_FIX_PARALLEL_MCEXIT = value)
    expect_true(should_enable_parallel_mcexit_fix(pkg))
  }
  for (value in c("false", "F", "No", "0")) {
    withr::local_envvar(COVR_FIX_PARALLEL_MCEXIT = value)
    expect_false(should_enable_parallel_mcexit_fix())
  }

  withr::local_envvar(COVR_FIX_PARALLEL_MCEXIT = "maybe")
  expect_snapshot(expect_true(should_enable_parallel_mcexit_fix()))
})


test_that("package_coverage() works with functions that send their code to other processes with callr", {
  skip_on_cran()
  skip_if_not_installed("callr")

  # callr removes the source references of the function it sends to the other
  # process, which fails if there is a function object in the function's code
  cov <- package_coverage(
    test_path("TestCallr"),
    type = "none",
    code = "stopifnot(identical(TestCallr::add_in_subprocess(1, 2), 3))"
  )

  df <- as.data.frame(cov)
  expect_equal(unique(df$functions), c("add_in_subprocess", "never_called"))
  # the call to callr::r() is counted, but the function sent to the other
  # process isn't, as the other process doesn't load the package
  expect_equal(df$value[df$functions == "add_in_subprocess"][[1]], 1)
  expect_equal(df$value[df$functions == "never_called"], 0)
})
