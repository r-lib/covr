test_that("c() adds the counts of shared traces and appends the others", {
  files <- local_add_subtract_files()
  cov_add <- file_coverage(files$src, files$test_add)
  cov_both <- file_coverage(files$src, files$test_both)

  merged <- c(cov_add, cov_both)
  expect_s3_class(merged, "coverage")
  expect_equal(tally_coverage(merged)$value, c(2, 1))
  expect_equal(percent_coverage(cov_add), 50)
  expect_equal(percent_coverage(merged), 100)

  other <- code_coverage("f <- function() 1", "f()")
  appended <- c(cov_add, other)
  expect_equal(names(appended), c(names(cov_add), names(other)))
  expect_equal(appended[[names(other)]]$value, 1)
})

test_that("c() keeps the first object's attributes and unions excluded lines", {
  x <- structure(
    list(t1 = list(value = 1L)),
    package = list(package = "pkg", path = "a"),
    root = "a",
    excluded_lines = list(R.R = c(1, 3)),
    class = "coverage"
  )
  y <- structure(
    list(t1 = list(value = 2L)),
    package = list(package = "pkg", path = "b"),
    root = "b",
    excluded_lines = list(R.R = c(2, 3), S.R = 4),
    class = "coverage"
  )
  merged <- c(x, y)
  expect_equal(attr(merged, "package")$path, "a")
  expect_equal(attr(merged, "root"), "a")
  expect_equal(
    attr(merged, "excluded_lines"),
    list(R.R = c(1, 2, 3), S.R = 4)
  )
})

test_that("c() errors for coverage of different packages", {
  cov <- function(package) {
    structure(
      list(t1 = list(value = 1L)),
      package = if (!is.null(package)) list(package = package),
      class = "coverage"
    )
  }
  expect_error(c(cov("a"), cov("b")), class = "covr_combine_error")
  expect_error(c(cov("a"), cov(NULL)), class = "covr_combine_error")
  expect_equal(c(cov(NULL), cov(NULL))$t1$value, 2L)
})

test_that("c() errors if an argument isn't a coverage object", {
  cov <- structure(list(t1 = list(value = 1L)), class = "coverage")
  expect_error(
    c(cov, list(t1 = list(value = 1L))),
    class = "covr_combine_error"
  )
})

test_that("c() drops NULL arguments", {
  cov <- structure(list(t1 = list(value = 1L)), class = "coverage")
  expect_equal(c(cov, NULL, cov)$t1$value, 2L)
})

test_that("c() only keeps the type if all objects have it", {
  cov <- function(type) {
    structure(list(t1 = list(value = 1L)), type = type, class = "coverage")
  }
  expect_equal(attr(c(cov("tests"), cov("tests")), "type"), "tests")
  expect_null(attr(c(cov("tests"), cov("examples")), "type"))
  expect_null(attr(c(cov("tests"), cov(NULL)), "type"))
})
