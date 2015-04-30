exclude_ops <- list(exclude_pattern = "#TeSt_NoLiNt"
                    exclude_start = "#TeSt_NoLiNt_StArT"
                    exclude_end = "#TeSt_NoLiNt_EnD")

context("parse_exclusions")
test_that("it returns an empty vector if there are no exclusions", {
  t1 <- c("this",
          "is",
          "a",
          "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops, recursive=F)), numeric(0))
})

test_that("it returns the line if one line is excluded", {

  t1 <- c("this",
          "is #TeSt_NoLiNt",
          "a",
          "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(2))

  t2 <- c("this",
          "is #TeSt_NoLiNt",
          "a",
          "test #TeSt_NoLiNt")
  expect_equal(do.call(parse_exclusions, c(list(t2), exclude_ops)), c(2, 4))
})

test_that("it returns all lines between start and end", {

  t1 <- c("this #TeSt_NoLiNt_StArT",
          "is",
          "a #TeSt_NoLiNt_EnD",
          "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(1, 2, 3))

  t2 <- c("this #TeSt_NoLiNt_StArT",
          "is",
          "a #TeSt_NoLiNt_EnD",
          "test",
          "of",
          "the #TeSt_NoLiNt_StArT",
          "emergency #TeSt_NoLiNt_EnD",
          "broadcast",
          "system")
  expect_equal(do.call(parse_exclusions, c(list(t2), exclude_ops)), c(1, 2, 3, 6, 7))
})

test_that("it ignores exclude coverage lines within start and end", {

    t1 <- c("this #TeSt_NoLiNt_StArT",
            "is #TeSt_NoLiNt",
            "a #TeSt_NoLiNt_EnD",
            "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(1, 2, 3))
})

test_that("it throws an error if start and end are unpaired", {

  t1 <- c("this #TeSt_NoLiNt_StArT",
          "is #TeSt_NoLiNt",
          "a",
          "test")
  expect_error(do.call(parse_exclusions, c(list(t1), exclude_ops)), "but only")
})

context("normalize_exclusions")
test_that("it merges two NULL or empty objects as an empty list", {
  expect_equal(normalize_exclusions(c(NULL, NULL)), list())
  expect_equal(normalize_exclusions(c(NULL, list())), list())
  expect_equal(normalize_exclusions(c(list(), NULL)), list())
  expect_equal(normalize_exclusions(c(list(), list())), list())
})

test_that("it returns the object if the other is NULL", {
  t1 <- list(a = 1:10)

  expect_equal(normalize_exclusions(c(t1, NULL)), t1)
  expect_equal(normalize_exclusions(c(NULL, t1)), t1)
})

test_that("it returns the union of two non-overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 20:30)

  expect_equal(normalize_exclusions(c(t1, t2)), list(a = c(1:10, 20:30)))
})

test_that("it returns the union of two overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 5:15)

  expect_equal(normalize_exclusions(c(t1, t2)), list(a = 1:15))
})

test_that("it adds names if needed", {
  t1 <- list(a = 1:10)
  t2 <- list(b = 5:15)

  expect_equal(normalize_exclusions(c(t1, t2)), list(a = 1:10, b = 5:15))
})

test_that("it handles full file exclusions", {

  expect_equal(normalize_exclusions(list("a")), list(a = Inf))

  expect_equal(normalize_exclusions(list("a", b = 1)), list(a = Inf, b = 1))
})

test_that("it handles redundant lines", {

  expect_equal(normalize_exclusions(list(a=c(1, 1, 1:10))), list(a = 1:10))

  expect_equal(normalize_exclusions(list(a=c(1, 1, 1:10), b = 1:10)), list(a = 1:10, b = 1:10))
})

test_that("it handles redundant files", {

  expect_equal(normalize_exclusions(list(a=c(1:10), a=c(10:20))), list(a = 1:20))
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

  expect_equal(length(t1), 3)
})
