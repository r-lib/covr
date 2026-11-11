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

test_that("save_trace does not save environments referenced by srcfiles", {
  # The srcfiles of installed packages have promises to lazy-load their lines
  # and parse data, evaluated in an environment that references the
  # environments of the package (#602). Packages can also add bindings to
  # srcfiles, e.g. this.path adds an environment.
  pkg_env <- new.env()
  srcfile <- srcfilecopy("R/f.R", character())
  delayedAssign("lines", "f <- function() 1", pkg_env, srcfile)
  delayedAssign("parseData", NULL, pkg_env, srcfile)
  srcfile$context <- new.env(parent = pkg_env)
  clear_counters()
  withr::defer(clear_counters())
  new_counter(srcref(srcfile, c(1, 1, 1, 17, 1, 17, 1, 1)), "f")

  local_mocked_bindings(
    save_rds = function(object, file) {
      saveRDS(object, file, refhook = function(env) {
        if (identical(env, pkg_env)) stop("saved the package environment")
      })
    }
  )
  trace <- merge_coverage(save_trace(withr::local_tempdir()))
  expect_equal(
    getSrcLines(attr(trace[[1]]$srcref, "srcfile"), 1, 1),
    "f <- function() 1"
  )
})

test_that("save_trace does not copy active bindings or unforced promises of srcfiles", {
  srcfile <- srcfilecopy("R/f.R", "f <- function() 1")
  makeActiveBinding("active", function() stop("ran active binding"), srcfile)
  delayedAssign("promise", stop("ran promise"), assign.env = srcfile)

  copy <- portable_srcfiles(list(srcfile))[[1]]
  expect_length(
    intersect(c("active", "promise"), ls(copy, all.names = TRUE)),
    0L
  )
  expect_equal(copy$lines, "f <- function() 1")
})

test_that("save_trace errors if the trace file can't be written", {
  local_mocked_bindings(save_rds = function(object, file) NULL)
  dir <- file.path(withr::local_tempdir(), "missing")
  err <- tryCatch(suppressWarnings(save_trace(dir)), error = conditionMessage)
  expect_match(err, "Can't write trace file")
})

test_that("unsaved_traces ignores the markers of the current process", {
  dir <- withr::local_tempdir()
  pid <- Sys.getpid()
  file.create(file.path(dir, paste0("covr_pending_", pid, "_a")))
  file.create(file.path(dir, paste0("covr_pending_", pid, "0_b")))

  expect_equal(unsaved_traces(dir), paste0("covr_pending_", pid, "0_b"))
})
