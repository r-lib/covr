test_that("function_coverage", {
  withr::with_options(c(keep.source = TRUE), {
    f <- function(x) {
      x + 1
    }
    expect_equal(
      as.numeric(function_coverage("f", env = environment(f))[[1]]$value),
      0
    )

    expect_equal(
      as.numeric(function_coverage("f", env = environment(f), f(1))[[1]]$value),
      1
    )

    expect_equal(
      as.numeric(
        function_coverage("f", env = environment(f), f(1), f(1))[[1]]$value
      ),
      2
    )
  })
})

test_that("function_coverage identity function", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x) {
      x
    }

    cov_num <- function(...) {
      as.numeric(
        function_coverage("fun", env = environment(fun), ...)[[1]]$value
      )
    }

    expect_equal(cov_num(), 0)
    expect_equal(cov_num(fun(1)), 1)
  })
})

test_that("function_coverage return last expr", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x = 1) {
      x
      x <- 1
    }

    cov_fun <- function(...) {
      vdapply(
        function_coverage("fun", env = environment(fun), ...),
        "[[",
        "value"
      )
    }

    expect_equal(as.numeric(cov_fun()), c(0L, 0L))
    expect_equal(as.numeric(cov_fun(fun())), c(1L, 1L))
  })
})

test_that("duplicated first_line", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function() {
      # fmt: skip
      res <- lapply(1:2, function(x) { x + 1 }) # nolint
    }
    cov <- function_coverage("fun", env = environment(fun))
    first_lines <- as.data.frame(cov)$first_line
    expect_equal(length(first_lines), 2)
    expect_equal(first_lines[1], first_lines[2])
  })
})

test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})

covr_error_for <- function(lines, prompt = TRUE) {
  td <- tempfile()
  dir.create(td)
  withr::defer(unlink(td, recursive = TRUE), parent.frame())
  writeLines(
    c(if (prompt) c("header", ">"), lines),
    file.path(td, "x.Rout.fail")
  )
  err <- tryCatch(show_failures(td), covr_error = function(e) e)
  err$file <- "x.Rout.fail"
  err
}

test_that("covr_error keeps full output and a bounded message", {
  skip_if_not(l10n_info()$`UTF-8`)
  td <- tempfile()
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE))
  out <- file.path(td, "test.Rout.fail")
  body <- paste0("\u2714 line ", 1:200, " \u2550\u2550")
  # multibyte body where bytes - warning.length exceeds nchar (old bug)
  writeLines(
    enc2utf8(c("R version header", "more header", ">", body)),
    out,
    useBytes = TRUE
  )
  expect_gt(sum(nchar(body, "bytes")) - 300, sum(nchar(body, "chars")))

  withr::local_options(warning.length = 300)
  err <- expect_error(show_failures(td), class = "covr_error")
  expect_equal(err$file, out)
  # header skipped, whole output kept
  expect_equal(err$output, c(">", body))
  msg <- conditionMessage(err)
  expect_lte(nchar(msg, "chars"), 300 - 9)
  expect_match(msg, "line 200", fixed = TRUE)
  expect_no_match(msg, "line 1 ", fixed = TRUE)
  expect_no_match(msg, "R version header", fixed = TRUE)
})

test_that("covr_error message is capped at the default number of lines", {
  withr::local_options(warning.length = 8170)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(msg[-1], paste0("line ", 71:120))
  expect_length(err$output, 121)
})

test_that("covr.failure_lines sets the number of lines in the message and print", {
  withr::local_options(warning.length = 8170, covr.failure_lines = 5)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(msg[-1], paste0("line ", 116:120))
  expect_equal(
    utils::tail(strsplit(format(err), "\n")[[1]], 5),
    paste0("line ", 116:120)
  )
})

test_that("covr_error print shows the last n lines", {
  err <- covr_error_for(paste0("line ", 1:10))
  expect_snapshot({
    print(err, n = 3)
    print(err, n = Inf)
  })
})

test_that("show_failures handles output without a prompt", {
  err <- covr_error_for(c("a", "b"), prompt = FALSE)
  expect_equal(err$output, c("a", "b"))
})

test_that("clean_coverage_tests works with degenerated objects", {
  obj <- list(
    a = list(tests = new.env()),
    tests = structure(
      list(structure(
        list("a", "b"),
        call_count = 1L
      )),
      names = ""
    ),
    b = list(value = integer(0)),
    c = list(value = NA)
  )

  expect_no_error(
    covr:::clean_coverage_tests(obj)
  )
})

test_that("merge_coverage sums the counts of shared traces", {
  a <- list(t1 = list(value = 1L), t2 = list(value = 2L))
  b <- list(t2 = list(value = 3L), t3 = list(value = 4L), t1 = list(value = 5L))
  merged <- merge_coverage(list(a, b))
  expect_equal(names(merged), c("t1", "t2", "t3"))
  expect_equal(
    vapply(merged, `[[`, integer(1), "value"),
    c(t1 = 6L, t2 = 5L, t3 = 4L)
  )
})

test_that("re-tracing an already traced namespace keeps the counts (#641)", {
  cov <- package_coverage(
    test_path("TestSummary"),
    type = "none",
    code = c(
      "invisible(TestSummary::test_me(1, 2))",
      "covr:::trace_environment(asNamespace('TestSummary'))"
    )
  )
  expect_equal(percent_coverage(cov), 50)
})

test_that("package_coverage keeps install_path only when coverage fails", {
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)
  expect_error(
    package_coverage(test_path("TestFailure"), install_path = install_path),
    class = "covr_error"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")

  install_path <- tempfile("R_LIBS")
  package_coverage(test_path("TestSummary"), install_path = install_path)
  expect_false(dir.exists(install_path))
})

test_that("package_coverage passes outDir to testInstalledPackage", {
  out_dir <- file.path(tempfile(), "out")
  on.exit(unlink(dirname(out_dir), recursive = TRUE), add = TRUE)
  package_coverage(test_path("TestSummary"), outDir = out_dir)
  expect_contains(
    list.files(out_dir, recursive = TRUE),
    "TestSummary-tests/testthat.Rout"
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
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)
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

test_that("merge_coverage reports corrupt trace files with a covr_error", {
  dir <- withr::local_tempdir()
  good <- file.path(dir, "covr_trace_good")
  bad <- file.path(dir, "covr_trace_bad")
  saveRDS(list(t1 = list(value = 1L)), good)
  writeBin(head(readBin(good, "raw", 1000), 10), bad)

  expect_error(
    merge_coverage(c(good, bad)),
    "covr_trace_bad.*incomplete",
    class = "covr_error"
  )
})

test_that("merge_coverage reports error markers with the original message", {
  dir <- withr::local_tempdir()
  marker <- file.path(dir, "covr_trace_marker")
  saveRDS(
    structure(
      list(message = "cannot serialize ALTREP", pid = 123L),
      class = "covr_trace_error"
    ),
    marker
  )

  expect_error(
    merge_coverage(marker),
    "covr_trace_marker.*cannot serialize ALTREP",
    class = "covr_error"
  )
})

test_that("bad trace files can be skipped with the covr_continue restart", {
  dir <- withr::local_tempdir()
  good <- file.path(dir, "covr_trace_good")
  bad <- file.path(dir, "covr_trace_bad")
  saveRDS(list(t1 = list(value = 1L)), good)
  writeBin(as.raw(1:5), bad)

  merged <- withCallingHandlers(
    merge_coverage(c(bad, good)),
    covr_error = function(e) invokeRestart("covr_continue")
  )
  expect_equal(merged$t1$value, 1L)
})

test_that("save_trace writes only complete covr_trace_ files", {
  dir <- withr::local_tempdir()
  save_trace(dir)
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  expect_length(files, 1)
  expect_match(files, "^covr_trace_")
  expect_no_error(readRDS(file.path(dir, files)))
})

test_that("save_trace writes an error marker when serialization fails", {
  local_mocked_bindings(
    save_rds = function(object, file) {
      if (!inherits(object, "covr_trace_error")) {
        stop("boom")
      }
      saveRDS(object, file)
    }
  )
  dir <- withr::local_tempdir()
  save_trace(dir)
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  expect_length(files, 1)
  expect_match(files, "^covr_trace_")
  expect_error(
    merge_coverage(file.path(dir, files)),
    "boom",
    class = "covr_error"
  )
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

test_that("unsaved_traces ignores the markers of the current process", {
  dir <- withr::local_tempdir()
  pid <- Sys.getpid()
  file.create(file.path(dir, paste0("covr_pending_", pid, "_a")))
  file.create(file.path(dir, paste0("covr_pending_", pid, "0_b")))

  expect_equal(unsaved_traces(dir), paste0("covr_pending_", pid, "0_b"))
})
