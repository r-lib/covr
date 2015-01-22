context("parse_exclusions")
test_that("it returns an empty vector if there are no exclusions", {
  t1 <- tempfile()
  on.exit(unlink(t1))
  writeLines(
    c("this",
      "is",
      "a",
      "test"), t1)
  expect_equal(parse_exclusions(t1), numeric(0))
})

test_that("it returns the line if one line is excluded", {
  t1 <- tempfile()
  on.exit(unlink(t1))
  writeLines(
    c("this",
      "is # EXCLUDE COVERAGE",
      "a",
      "test"), t1)
  expect_equal(parse_exclusions(t1), c(2))

  t2 <- tempfile()
  on.exit(unlink(t2))
  writeLines(
    c("this",
      "is # EXCLUDE COVERAGE",
      "a",
      "test # EXCLUDE COVERAGE"), t2)
  expect_equal(parse_exclusions(t2), c(2, 4))
})

test_that("it returns all lines between start and end", {
  t1 <- tempfile()
  on.exit(unlink(t1))
  writeLines(
    c("this # EXCLUDE COVERAGE START",
      "is",
      "a # EXCLUDE COVERAGE END",
      "test"), t1)
  expect_equal(parse_exclusions(t1), c(1, 2, 3))

  t2 <- tempfile()
  on.exit(unlink(t2))
  writeLines(
    c("this # EXCLUDE COVERAGE START",
      "is",
      "a # EXCLUDE COVERAGE END",
      "test",
      "of",
      "the # EXCLUDE COVERAGE START",
      "emergency # EXCLUDE COVERAGE END",
      "broadcast",
      "system"
      ), t2)
  expect_equal(parse_exclusions(t2), c(1, 2, 3, 6, 7))
})

test_that("it ignores exclude coverage lines within start and end", {
  t1 <- tempfile()
  on.exit(unlink(t1))
  writeLines(
    c("this # EXCLUDE COVERAGE START",
      "is # EXCLUDE COVERAGE",
      "a # EXCLUDE COVERAGE END",
      "test"), t1)
  expect_equal(parse_exclusions(t1), c(1, 2, 3))
})

test_that("it throws an error if start and end are unpaired", {
  t1 <- tempfile()
  on.exit(unlink(t1))
  writeLines(
    c("this # EXCLUDE COVERAGE START",
      "is # EXCLUDE COVERAGE",
      "a",
      "test"), t1)
  expect_error(parse_exclusions(t1), "but only")
})

context("merge_exclusions")
test_that("it merges two NULL or empty objects as an empty list", {
  expect_equal(merge_exclusions(NULL, NULL), list())
  expect_equal(merge_exclusions(NULL, list()), list())
  expect_equal(merge_exclusions(list(), NULL), list())
  expect_equal(merge_exclusions(list(), list()), list())
})
test_that("it returns the object if the other is NULL", {
  t1 <- list(a = 1:10)

  expect_equal(merge_exclusions(t1, NULL), t1)
  expect_equal(merge_exclusions(NULL, t1), t1)
})
test_that("it returns the union of two non-overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 20:30)

  expect_equal(merge_exclusions(t1, t2), list(a = c(1:10, 20:30)))
})
test_that("it returns the union of two overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 5:15)

  expect_equal(merge_exclusions(t1, t2), list(a = 1:15))
})
test_that("it adds names if needed", {
  t1 <- list(a = 1:10)
  t2 <- list(b = 5:15)

  expect_equal(merge_exclusions(t1, t2), list(a = 1:10, b = 5:15))
})

context("exclude")
test_that("it excludes lines", {
  t1 <- package_coverage("TestSummary")

  expect_equal(length(t1), 2)
  expect_equal(length(exclude(t1, list("R/TestSummary.R" = 3))), 1)
  expect_equal(length(exclude(t1, list("R/TestSummary.R" = 8))), 1)
})
test_that("it preserves the class", {
  t1 <- package_coverage("TestSummary")

  expect_equal(class(exclude(t1, NULL)), class(t1))
  expect_equal(class(exclude(t1, list("R/TestSummary.R" = 3))), class(t1))
})

test_that("it excludes properly", {
  t1 <- package_coverage("TestExclusion")

  expect_equal(length(exclude(t1)), 3)
})
