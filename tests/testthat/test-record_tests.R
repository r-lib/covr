context("record_tests")

cov_func <- withr::with_options(
  list(covr.record_tests = TRUE),
  package_coverage(test_path("TestFunctional")))

cov_tests_not_recorded <- withr::with_options(
  list(covr.record_tests = NULL),
  package_coverage(test_path("TestFunctional")))


test_that("covr.record_tests causes test traces to be recorded", {
  expect_gt(length(attr(cov_func, "tests")), 0L)
  expect_gt(length(attr(cov_func, "tests")[[1]]), 0L)
})


test_that("covr.record_tests records test indices and depth for each trace", {
  expect_equal(ncol(cov_func[[1]]$tests), 3L)
  expect_equal(colnames(cov_func[[1]]$tests), c("test", "depth", "i"))
})


test_that("covr.record_tests test traces list uses srcref key names", {
  expect_match(names(attr(cov_func, "tests")), "\\w+(:\\d+){4,8}")
})


test_that("covr.record_tests=NULL does not record tests", {
  expect_null(attr(cov_tests_not_recorded, "tests"))
  expect_null(cov_tests_not_recorded[[1]]$tests$tally)
})


test_that("covr.record_tests traces to tests nested within test directory", {
  cov_top_level <- withr::with_envvar(
    list(COVR_TEST_NESTED = "FALSE"),
    package_coverage(test_path("TestNestedTestDirs")))

  cov_nested <- withr::with_envvar(
    list(COVR_TEST_NESTED = "TRUE"),
    cov_nested <- package_coverage(test_path("TestNestedTestDirs")))

  # same test file is evaluated twice more in a nested directory
  expect_equal(length(attr(cov_top_level, "tests")) * 3L, length(attr(cov_nested, "tests")))
})


test_that("covr.record_tests: merging coverage objects appends tests", {
  # recreate some ".counters" objects for testing
  .counter_1 <- list(
    tests = list(
      `./test1:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test1", { expect_true(a()) })),
        quote(expect_true(a())),
        quote(a())
      ),
      `./test2:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test2", { expect_true(a()) })),
        quote(expect_true(a())),
        quote(a())
      )
    ),
    `a:1:2:3:4:5:6:7:8` = list(
      value = 2L,
      tests = as.environment(list(tally = cbind(test = c(1, 2), depth = c(0, 1), i = c(1, 3))))
    ),
    `b:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(tally = cbind(test = c(2), depth = c(0), i = c(2))))
    )
  )

  .counter_2 <- list(
    tests = list(
      `./test1:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test1", { expect_true(a()) })),
        quote(expect_true(a())),
        quote(a())
      ),
      `./test3:1:2:3:4:5:6:7:8` = list(
        quote(test_that("test3", { expect_true(a()) })),
        quote(expect_true(a())),
        quote(a())
      )
    ),
    `a:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(tally = cbind(test = c(2), depth = c(0), i = c(1))))
    ),
    `c:1:2:3:4:5:6:7:8` = list(
      value = 1L,
      tests = as.environment(list(tally = cbind(test = c(2), depth = c(0), i = c(2))))
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
  expect_equal(cov_merged$`a:1:2:3:4:5:6:7:8`$tests$tally[[3L,1L]], 3L)
})


test_that("covr.record_tests: tests tally is pruned even when no tests are hit", {
  # "test" a function, but no code is executed and therefore no tests are logged
  fcode <- 'f <- function(x) { if (x) f(!x) else FALSE }'
  withr::with_options(c("covr.record_tests" = TRUE), cov <- code_coverage(fcode, "{ }"))

  # expect that no tests were recorded, as no expressions evaluated f
  expect_null(attr(cov, "tests"))

  # expect that a matrix was still produced by a counter and pruned to 0 rows
  expect_true(is.matrix(cov[[1L]]$tests))
  expect_equal(cov[[1L]]$value, 0L)
  expect_equal(nrow(cov[[1L]]$tests), 0L)
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


test_that("covr.record_tests: test that coverage objects contain expected test data", {
  fcode <- '
  f <- function(x) {
    if (x)
      f(!x)
    else
      FALSE
  }'

  withr::with_options(c("covr.record_tests" = TRUE), cov <- code_coverage(fcode, "f(TRUE)"))

  # expect 4 covr traces due to test
  expect_equal(sum(unlist(lapply(cov, function(i) nrow(i[["tests"]])))), 4L)

  # expect that all tests have the same index
  expect_equal(unique(unlist(lapply(cov, function(i) i[["tests"]][,"test"]))), 1L)

  # expect execution order index to be the same length as the number of traces
  expect_equal(length(unique(unlist(lapply(cov, function(i) i[["tests"]][,"i"])))), 4L)

  # expect that there are two distinct stack depths (`if (x)` (@1), `TRUE` (@2), `FALSE` (@2))
  expect_equal(length(unique(unlist(lapply(cov, function(i) i[["tests"]][,"depth"])))), 2L)
})

test_that("covr.record_tests: safely handles extremely large calls", {
  skip_on_cran()
  skip_if(is_r_devel())

  fcode <- 'f <- function(...) { sum(...) }'

  expect_warning(
    withr::with_options(c("covr.record_tests" = TRUE), {
      cov <- code_coverage(fcode, "do.call('f', as.list(rep_len(1L, 1e6)))")
    }),
    "large call .* truncated"
  )

  # expect that all calls in recorded test call stacks are under call length limit
  expect_true(all(vapply(attr(cov, "tests")[[1L]], length, numeric(1L)) < 1e5))

  # add a canary to test for R updates that handle large call deserialization
  # more gracefully
  suppressWarnings({
    code <- deparse(quote({
      x <- as.call(c(list("f"), as.list(rep_len(1L, 1e6))))
      f <- tempfile("test_rds", fileext = ".Rds")
      saveRDS(x, f)
      readRDS(f)
    }))

    r_script <- tempfile("test_rds_script", fileext = ".R")
    writeLines(code, r_script)
    res <- system2(file.path(R.home("bin"), "R"), list("-q", "-s", "--vanilla", "-f", r_script), stdout = TRUE, stderr = TRUE)
  })

  if (attr(res, "status") == 0L) {
    warning(paste0(collapse = "\n", strwrap(paste0(
      "Looks like R was updated and the work-around for Rds ",
      "deserialization segfaults can now be made to apply conditionally to only ",
      "legacy R versions. Search for 'NOTE: r-bugs 18348' in the covr ",
      "codebase to find and add necessary R version condition to the affected ",
      "code"
    ))))
  }

})
