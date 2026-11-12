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

test_that("clean_coverage_tests keeps tallies with fewer rows than hits", {
  tally <- cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
  obj <- list(a = list(value = 3L, tests = as.environment(list(tally = tally))))

  clean_coverage_tests(obj)

  expect_equal(obj$a$tests$tally, tally)
})

test_that("merge_coverage_pair handles an object with an empty tests list", {
  tally <- cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
  into <- list(
    tests = list(test1 = list(quote(a()))),
    a = list(value = 1L, tests = as.environment(list(tally = tally)))
  )
  from <- list(tests = list(), a = list(value = 2L))

  merged <- merge_coverage_pair(into, from)

  expect_equal(names(merged$tests), "test1")
  expect_equal(merged$a$value, 3L)
  expect_equal(merged$a$tests$tally, tally)
})

test_that("coverage of a file whose name starts with `tests` is not read as recorded tests", {
  dir <- withr::local_tempdir()
  src <- file.path(dir, "tests.R")
  test <- file.path(dir, "test-f.R")
  writeLines("f <- function() 1", src)
  writeLines("f()", test)

  cov <- file_coverage(src, test)
  expect_length(cov, 1)
  expect_null(attr(cov, "tests"))
  expect_snapshot(tally_tests(cov), error = TRUE)

  expect_equal(unname(value(c(cov, cov))), 2)
  expect_null(attr(c(cov, cov), "tests"))
})

test_that("merge_coverage_pair reads the tests element exactly", {
  tally <- cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
  into <- list(tests.R = list(value = 1L))
  from <- list(
    tests = list(test1 = list(quote(a()))),
    tests.R = list(value = 2L, tests = as.environment(list(tally = tally)))
  )
  merged <- merge_coverage_pair(into, from)
  expect_equal(names(merged[["tests"]]), "test1")
  expect_equal(merged$tests.R$value, 3L)

  merged <- merge_coverage_pair(into, list(tests.R = list(value = 2L)))
  expect_equal(merged$tests.R$value, 3L)
  expect_null(merged[["tests"]])
})

test_that("merge_coverage returns NULL for no coverage", {
  expect_null(merge_coverage(list()))
  expect_null(merge_coverage(character()))
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

test_that("traces of processes that restored saved counters are merged with them", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  src <- srcfilecopy("a.R", c("x", "y"))
  counters <- new.env()
  counters[["a.R:1"]] <- list(
    value = 0,
    srcref = srcref(src, c(1, 1, 1, 1)),
    functions = "f"
  )
  counters[["a.R:2"]] <- list(
    value = 0,
    srcref = srcref(src, c(2, 1, 2, 1)),
    functions = "f"
  )
  file <- withr::local_tempfile()
  saveRDS(portable_srcfiles(counters), file)
  restore_counters(new.env(), file)
  dir <- withr::local_tempdir()

  # A function instrumented when the package is loaded
  b <- srcfilecopy("b.R", "z")
  key_b <- new_counter(srcref(b, c(1, 1, 1, 1)), "g")
  .Call(covr_count, "a.R:1")
  .Call(covr_count, key_b)
  save_trace(dir)
  zero_counters()
  .Call(covr_count, "a.R:1")
  .Call(covr_count, "a.R:1")
  save_trace(dir)

  merged <- merge_coverage(list.files(dir, full.names = TRUE))
  values <- vapply(merged, function(x) x$value, numeric(1))
  expect_equal(
    values[sort(names(values), method = "radix")],
    stats::setNames(c(3, 0, 1), c("a.R:1", "a.R:2", key_b))
  )
  expect_equal(
    getSrcLines(attr(merged[["a.R:2"]]$srcref, "srcfile"), 2, 2),
    "y"
  )
  expect_equal(merged[[key_b]]$functions, "g")
})

test_that("saved counters are merged if no process counted any of them", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  src <- srcfilecopy("a.R", "x")
  counters <- new.env()
  counters[["a.R:1"]] <- list(
    value = 0,
    srcref = srcref(src, c(1, 1, 1, 1)),
    functions = "f"
  )
  file <- withr::local_tempfile()
  saveRDS(portable_srcfiles(counters), file)
  restore_counters(new.env(), file)

  merged <- merge_coverage(save_trace(withr::local_tempdir()))
  expect_named(merged, "a.R:1")
  expect_equal(merged[["a.R:1"]]$value, 0)
})

test_that("merge_coverage reports a missing file of saved counters", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  counters <- new.env()
  counters[["a.R:1"]] <- list(value = 0, functions = "f")
  file <- withr::local_tempfile()
  saveRDS(counters, file)
  restore_counters(new.env(), file)
  trace <- save_trace(withr::local_tempdir())
  unlink(file)

  expect_error(merge_coverage(trace), "incomplete", class = "covr_error")
})
