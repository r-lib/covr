test_that("covr.record_tests records tests, their indices and depth, and uses srcref key names", {
  cov <- functional_coverage()
  tests <- attr(cov, "tests")
  expect_gt(length(tests), 0L)
  expect_gt(length(tests[[1]]), 0L)
  expect_match(names(tests), "\\w+(:\\d+){4,8}")

  trace <- trace_with_source(cov, "return(TRUE)")
  expect_equal(ncol(trace$tests), 4L)
  expect_equal(colnames(trace$tests), c("test", "call", "depth", "i"))
})

test_that("covr.record_tests=NULL does not record tests", {
  cov <- functional_coverage(record_tests = FALSE)
  expect_null(attr(cov, "tests"))
  expect_null(trace_with_source(cov, "return(TRUE)")$tests$tally)
})

test_that("tally_tests() lists the tests that ran each line", {
  res <- tally_tests(functional_coverage())
  expect_equal(res$filename, rep("R/a.R", 4))
  expect_equal(res$line, c(4, 4, 6, 8))
  expect_equal(res$test_file, rep("tests/testthat/test-a.R", 4))
  expect_equal(res$test_line, c(2, 3, 2, 3))
  expect_equal(res$test, rep("regular function `a` works as expected", 4))
})


test_that("covr.record_tests keys tests by the test files' calls", {
  # The package is called from code with srcrefs outside the test files, like
  # rlang's eval_bare() when rlang is installed with source references.
  cov <- withr::with_options(
    list(covr.record_tests = TRUE),
    package_coverage(test_path("TestRecordTests"))
  )
  res <- tally_tests(cov)
  expect_equal(res$test_file, rep("tests/testthat/test-f.R", 2))
  expect_equal(res$test_line, c(5, 6))
})


test_that("tally_tests() counts the times each test ran a line", {
  cov <- withr::with_options(
    list(covr.record_tests = TRUE),
    code_coverage(
      "f <- function(n) {\n  for (i in seq_len(n)) {\n    i\n  }\n}",
      "f(3)\nf(1)"
    )
  )
  res <- tally_tests(cov)
  expect_equal(res$line[res$test_line == 1], c(2, 3))
  expect_equal(res$value[res$test_line == 1], c(1, 3))
  expect_equal(res$value[res$test_line == 2], c(1, 1))
})


test_that("tally_tests() errors without recorded tests", {
  cov <- functional_coverage(record_tests = FALSE)
  expect_snapshot(tally_tests(cov), error = TRUE)
})


test_that("covr.record_tests traces to tests nested within test directory", {
  cov_top_level <- withr::with_envvar(
    list(COVR_TEST_NESTED = "FALSE"),
    package_coverage(test_path("TestNestedTestDirs"))
  )

  cov_nested <- withr::with_envvar(
    list(COVR_TEST_NESTED = "TRUE"),
    cov_nested <- package_coverage(test_path("TestNestedTestDirs"))
  )

  # same test file is evaluated twice more in a nested directory
  expect_equal(
    length(attr(cov_top_level, "tests")) * 3L,
    length(attr(cov_nested, "tests"))
  )
})


test_that("covr.record_tests: merging coverage objects appends tests", {
  # recreate some ".counters" objects for testing
  .counter_1 <- list(
    tests = list(
      `./test1:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test1", {
          expect_true(a())
        })),
        quote(expect_true(a())),
        quote(a())
      ),
      `./test2:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test2", {
          expect_true(a())
        })),
        quote(expect_true(a())),
        quote(a())
      )
    ),
    `a:1:2:3:4:5:6:7:8` = list(
      value = 2L,
      tests = as.environment(list(
        tally = cbind(test = c(1, 2), depth = c(0, 1), i = c(1, 3))
      ))
    ),
    `b:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = c(2), depth = c(0), i = c(2))
      ))
    )
  )

  .counter_2 <- list(
    tests = list(
      `./test1:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test1", {
          expect_true(a())
        })),
        quote(expect_true(a())),
        quote(a())
      ),
      `./test3:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test3", {
          expect_true(a())
        })),
        quote(expect_true(a())),
        quote(a())
      )
    ),
    `a:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = c(2), depth = c(0), i = c(1))
      ))
    ),
    `c:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = c(2), depth = c(0), i = c(2))
      ))
    )
  )

  # store sum total of individual counters. store before merge, as the first
  # will be modified in-place during merging.
  counter_total <-
    nrow(.counter_1$`a:1:2:3:4:5:6:7:8`$tests$tally) +
    nrow(.counter_2$`a:1:2:3:4:5:6:7:8`$tests$tally)

  expect_silent(cov_merged <- merge_coverage.list(list(.counter_1, .counter_2)))
  expect_equal(nrow(cov_merged$`a:1:2:3:4:5:6:7:8`$tests$tally), counter_total)
  expect_equal(length(cov_merged$tests), 3L)
  expect_equal(cov_merged$`a:1:2:3:4:5:6:7:8`$tests$tally[[3L, 1L]], 3L)
})

test_that("covr.record_tests: merging renumbers tests of traces only in later objects", {
  .counter_1 <- list(
    tests = list(test1 = list(quote(a())), test2 = list(quote(b()))),
    a = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
      ))
    )
  )
  .counter_2 <- list(
    tests = list(test1 = list(quote(a())), test3 = list(quote(c()))),
    a = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
      ))
    ),
    c = list(
      value = 1L,
      tests = as.environment(list(
        tally = cbind(test = 2L, call = 1L, depth = 0L, i = 2L)
      ))
    )
  )

  cov_merged <- merge_coverage(list(.counter_1, .counter_2))
  expect_equal(names(cov_merged$tests), c("test1", "test2", "test3"))
  expect_equal(
    names(cov_merged$tests)[cov_merged$c$tests$tally[, "test"]],
    "test3"
  )
})


test_that("covr.record_tests: tests tally is pruned even when no tests are hit", {
  # "test" a function, but no code is executed and therefore no tests are logged
  fcode <- 'f <- function(x) { if (x) f(!x) else FALSE }'
  withr::with_options(
    c("covr.record_tests" = TRUE),
    cov <- code_coverage(fcode, "{ }")
  )

  # expect that no tests were recorded, as no expressions evaluated f
  expect_null(attr(cov, "tests"))

  # expect that a matrix was still produced by a counter and pruned to 0 rows
  for (trace in cov) {
    expect_length(dim(trace$tests), 2L)
    expect_equal(trace$value, 0L)
    expect_equal(nrow(trace$tests), 0L)
  }
  expect_equal(nrow(tally_tests(cov)), 0L)
})


test_that("covr.record_tests: merging coverage test objects doesn't break default tests", {
  # recreate some ".counters" objects for testing
  .counter_1 <- list(
    `a:1:2:3:4:5:6:7:8` = list(value = 2L),
    `b:1:2:3:4:5:6:7:8` = list(value = 2L)
  )

  .counter_2 <- list(
    `a:1:2:3:4:5:6:7:8` = list(value = 2L),
    `c:1:2:3:4:5:6:7:8` = list(value = 2L)
  )

  expect_silent(cov_merged <- merge_coverage(list(.counter_1, .counter_2)))
  expect_equal(cov_merged$`a:1:2:3:4:5:6:7:8`$value, 4L)
})

test_that("covr.record_tests: c() renumbers the recorded tests", {
  withr::local_options(covr.record_tests = TRUE)
  files <- local_add_subtract_files()
  cov_add <- file_coverage(files$src, files$test_add)
  cov_both <- file_coverage(files$src, files$test_both)

  merged <- c(cov_add, cov_both)
  tests <- attr(merged, "tests")
  expect_equal(
    names(tests),
    c(names(attr(cov_add, "tests")), names(attr(cov_both, "tests")))
  )

  test_names <- function(cov, fun) {
    trace <- cov[[which(vcapply(cov, `[[`, "functions") == fun)]]
    names(attr(cov, "tests"))[trace$tests[, "test"]]
  }
  expect_equal(
    test_names(merged, "add"),
    c(test_names(cov_add, "add"), test_names(cov_both, "add"))
  )
  expect_equal(test_names(merged, "subtract"), test_names(cov_both, "subtract"))
})


test_that("covr.record_tests: test that coverage objects contain expected test data", {
  fcode <- '
  f <- function(x) {
    if (x)
      f(!x)
    else
      FALSE
  }'

  withr::with_options(
    c("covr.record_tests" = TRUE),
    cov <- code_coverage(fcode, "f(TRUE)")
  )

  # expect 4 covr traces due to test
  expect_equal(sum(unlist(lapply(cov, function(i) nrow(i[["tests"]])))), 4L)

  # expect that all tests have the same index
  expect_equal(
    unique(unlist(lapply(cov, function(i) i[["tests"]][, "test"]))),
    1L
  )

  # expect execution order index to be the same length as the number of traces
  expect_equal(
    length(unique(unlist(lapply(cov, function(i) i[["tests"]][, "i"])))),
    4L
  )

  # expect that there are two distinct stack depths (`if (x)` (@1), `TRUE` (@2), `FALSE` (@2))
  expect_equal(
    length(unique(unlist(lapply(cov, function(i) i[["tests"]][, "depth"])))),
    2L
  )
})

test_that("covr.record_tests: safely handles extremely large calls", {
  skip_on_cran()
  skip_if(is_r_devel())

  fcode <- 'f <- function(...) { sum(...) }'

  expect_snapshot(
    withr::with_options(c("covr.record_tests" = TRUE), {
      cov <- code_coverage(fcode, "do.call('f', as.list(rep_len(1L, 1e6)))")
    })
  )

  # expect that all calls in recorded test call stacks are under call length limit
  expect_lt(max(lengths(attr(cov, "tests")[[1L]])), 1e5)

  # add a canary to test for R updates that handle large call deserialization
  # more gracefully
  suppressWarnings({
    code <- deparse(quote({
      x <- as.call(c(list("f"), as.list(rep_len(1L, 1e6))))
      f <- tempfile("test_rds", fileext = ".Rds")
      saveRDS(x, f)
      readRDS(f)
    }))

    r_script <- withr::local_tempfile(fileext = ".R")
    writeLines(code, r_script)
    res <- system2(
      file.path(R.home("bin"), "R"),
      list("-q", "-s", "--vanilla", "-f", r_script),
      stdout = TRUE,
      stderr = TRUE
    )
  })

  if (identical(attr(res, "status"), 0L)) {
    warning(paste0(
      collapse = "\n",
      strwrap(paste0(
        "Looks like R was updated and the work-around for Rds ",
        "deserialization segfaults can now be made to apply conditionally to only ",
        "legacy R versions. Search for 'NOTE: r-bugs 18348' in the covr ",
        "codebase to find and add necessary R version condition to the affected ",
        "code"
      ))
    ))
  }
})

test_that("covr.record_tests: records multiple calls to the same test expr", {
  fcode <- 'f1 <- function(...) "hello, world"; f2 <- function() c(1, 2, 3)'

  withr::with_options(c("covr.record_tests" = TRUE), {
    cov <- code_coverage(
      fcode,
      "for (i in 1:3) with(new.env(), { f1(); f2() })"
    )
  })

  trace_f1 <- which(vapply(cov, `[[`, character(1L), "functions") == "f1")
  expect_equal(cov[[trace_f1]]$tests[, "test"], c(1, 1, 1))
  expect_equal(cov[[trace_f1]]$tests[, "call"], c(1, 2, 3))

  trace_f2 <- which(vapply(cov, `[[`, character(1L), "functions") == "f2")
  expect_equal(cov[[trace_f2]]$tests[, "test"], c(2, 2, 2))
  expect_equal(cov[[trace_f2]]$tests[, "call"], c(1, 2, 3))
})

test_that("covr.record_tests: records repeated calls of tests without srcrefs once (#627)", {
  # The code is run with `R CMD BATCH`, without srcrefs, so the tests are
  # identified by their calls
  cov <- withr::with_options(
    c("covr.record_tests" = TRUE),
    package_coverage(
      test_path("TestFunctional"),
      type = "none",
      code = "for (i in 1:3) { a(); b() }"
    )
  )

  expect_length(attr(cov, "tests"), 2L)
  trace_a <- trace_with_source(cov, "return(TRUE)")
  expect_equal(trace_a$tests[, "test"], c(1, 1, 1))
  expect_equal(trace_a$tests[, "call"], c(1, 2, 3))
})

test_that("covr.record_tests: doesn't record environments of functions in calls", {
  skip_if_not_installed("R6")
  # When covr measures its own coverage, the outer instrumentation changes the
  # recorded calls. This checks `R_COVR` directly rather than using
  # `skip_on_covr()`, which `shim_package.sh` would rename.
  skip_if(identical(Sys.getenv("R_COVR"), "true"), "Running under covr")

  fcode <- '
  Counter <- R6::R6Class("Counter",
    public = list(
      data = NULL,
      initialize = function(data) self$data <- data
    ),
    active = list(
      size = function() length(self$data)
    )
  )
  apply_f <- function(f, x) f(x)
  '

  withr::with_options(c("covr.record_tests" = TRUE), {
    cov <- code_coverage(
      fcode,
      "counter <- Counter$new(1:10)
      stopifnot(counter$size == 10, counter$size == 10)
      do.call(apply_f, list(function(x) x, 1))"
    )
  })

  # the calls into the traced code: `initialize(...)`, the active binding and
  # apply_f with its argument from do.call()
  calls <- lapply(attr(cov, "tests"), function(trace) trace[[length(trace)]])
  fns <- Filter(is.function, do.call(c, lapply(unname(calls), as.list)))
  expect_equal(unname(lapply(fns, environment)), rep(list(emptyenv()), 3))
})

test_that("covr.record_tests: objects used in tests can be garbage collected (#627)", {
  skip_if_not_installed("R6")
  fcode <- '
  Counter <- R6::R6Class("Counter",
    public = list(add = function() invisible(self)),
    active = list(size = function() 1)
  )
  '
  events <- character()

  withr::with_options(c("covr.record_tests" = TRUE), {
    code_coverage(
      fcode,
      'local({
        counter <- Counter$new()
        reg.finalizer(counter, function(e) events <<- c(events, "method"))
        counter$add()
      })
      invisible(gc())
      events <<- c(events, "gc")
      local({
        counter <- Counter$new()
        reg.finalizer(counter, function(e) events <<- c(events, "active"))
        counter$size
      })
      invisible(gc())
      events <<- c(events, "gc")',
      parent_env = environment()
    )
  })

  # each object is collected by the `gc()` right after it is used
  expect_equal(events, c("method", "gc", "active", "gc"))
})

test_that("covr.record_tests tallies every hit of a trace", {
  # more hits than the initial 4 rows of the tally matrix
  withr::local_options(covr.record_tests = TRUE)
  cov <- package_coverage(
    test_path("TestFunctional"),
    type = "none",
    code = "for (i in 1:6) TestFunctional::a()"
  )

  tally <- trace_with_source(cov, "return(TRUE)")$tests
  expect_equal(nrow(tally), 6L)
  expect_equal(unname(tally[, "test"]), rep(1L, 6))
  expect_equal(unname(tally[, "i"]), seq(2L, 12L, by = 2L))
})

test_that("tally_tests() has no rows if all lines with test hits are excluded", {
  cov <- withr::with_options(
    list(covr.record_tests = TRUE),
    code_coverage("f <- function(x) {\n  x\n}", "f(1)")
  )
  file <- as.data.frame(cov)$filename[[1]]
  attr(cov, "excluded_lines") <- setNames(list(1:3), file)

  res <- tally_tests(cov)
  expect_equal(NROW(res), 0)
  expect_named(
    res,
    c(
      "filename",
      "functions",
      "line",
      "test_file",
      "test_line",
      "test",
      "value"
    )
  )
})

test_that("count_test ignores traces without a test counter", {
  withr::local_options(covr.record_tests = FALSE)
  clear_counters()
  withr::defer(clear_counters())
  key <- new_counter(parse_srcrefs("f(x)")$refs[[1]], "f")

  expect_null(count_test(key))
})

test_that("count_test ignores traces hit before a test is known", {
  withr::local_options(covr.record_tests = TRUE)
  clear_counters()
  withr::defer(clear_counters())
  key <- new_counter(parse_srcrefs("f(x)")$refs[[1]], "f")

  expect_null(count_test(key))
  expect_equal(unname(.counters[[key]]$tests$tally[1, ]), rep(NA_integer_, 4))
})

test_that("in_caller_body is FALSE for the first frame", {
  expect_false(in_caller_body(1L, quote(f())))
})
