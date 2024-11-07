exclude_ops <- list(exclude_pattern = "#TeSt_NoLiNt",
                    exclude_start = "#TeSt_NoLiNt_StArT",
                    exclude_end = "#TeSt_NoLiNt_EnD")

test_that("it returns an empty vector if there are no exclusions", {
  t1 <- c("this",
          "is",
          "a",
          "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops, recursive = F)), numeric(0))
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

expect_equal_vals <- function(x, y) {
  testthat::expect_equal(unname(x), unname(y))
}
test_that("it merges two NULL or empty objects as an empty list", {
  expect_equal(normalize_exclusions(c(NULL, NULL)), list())
  expect_equal(normalize_exclusions(c(NULL, list())), list())
  expect_equal(normalize_exclusions(c(list(), NULL)), list())
  expect_equal(normalize_exclusions(c(list(), list())), list())
})

test_that("it returns the object if the other is NULL", {
  t1 <- list(a = 1:10)

  expect_equal_vals(normalize_exclusions(c(t1, NULL)), t1)
  expect_equal_vals(normalize_exclusions(c(NULL, t1)), t1)
})

test_that("it returns the union of two non-overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 20:30)

  expect_equal_vals(normalize_exclusions(c(t1, t2)), list(a = c(1:10, 20:30)))
})

test_that("it returns the union of two overlapping lists", {
  t1 <- list(a = 1:10)
  t2 <- list(a = 5:15)

  expect_equal_vals(normalize_exclusions(c(t1, t2)), list(a = 1:15))
})

test_that("it adds names if needed", {
  t1 <- list(a = 1:10)
  t2 <- list(b = 5:15)

  expect_equal_vals(normalize_exclusions(c(t1, t2)), list(a = 1:10, b = 5:15))
})

test_that("it handles full file exclusions", {

  expect_equal_vals(normalize_exclusions(list("a")), list(a = Inf))

  expect_equal_vals(normalize_exclusions(list("a", b = 1)), list(a = Inf, b = 1))
})

test_that("it handles redundant lines", {

  expect_equal_vals(normalize_exclusions(list(a = c(1, 1, 1:10))), list(a = 1:10))

  expect_equal_vals(normalize_exclusions(list(a = c(1, 1, 1:10), b = 1:10)), list(a = 1:10, b = 1:10))
})

test_that("it handles redundant files", {

  expect_equal_vals(normalize_exclusions(list(a = c(1:10), a = c(10:20))), list(a = 1:20))
})

cov <- package_coverage("TestSummary")

test_that("it excludes lines", {
  expect_equal(length(cov), 4)
  expect_equal(length(exclude(cov, list("R/TestSummary.R" = 5), path = "TestSummary")), 3)
  expect_equal(length(exclude(cov, list("R/TestSummary.R" = 13), path = "TestSummary")), 3)
})
test_that("it preserves the class", {
  expect_equal(class(exclude(cov, NULL, path = "TestSummary")), class(cov))
  expect_equal(class(exclude(cov, list("R/TestSummary.R" = 3), path = "TestSummary")), class(cov))
})
test_that("function exclusions work", {
  expect_equal(length(exclude(cov, NULL, "^test")), 1)
  expect_equal(length(exclude(cov, NULL, c("^test", "dont"))), 0)
})

test_that("it excludes properly", {
  t1 <- package_coverage("TestExclusion")

  expect_equal(length(t1), 3)

  t1 <- package_coverage("TestExclusion", line_exclusions = "R/TestExclusion.R")

  expect_equal(length(t1), 0)
})

test_that("it returns NULL if empty or no file exclusions", {
  expect_equal(file_exclusions(NULL, ""), NULL)

  expect_equal(file_exclusions(list("a" = c(1, 2))), NULL)

  expect_equal(file_exclusions(list("a" = c(1, 2), "b" = c(3, 4))), NULL)
})
test_that("it returns a normalizedPath if the file can be found", {
  expect_match(file_exclusions(list("test-exclusions.R"), "."), "test-exclusions.R")

  expect_match(
    file_exclusions(list("testthat/test-exclusions.R", "testthat.R"), ".."),
    rex::rex(or("test-exclusions.R", "testthat.R")))
})

describe("covrignore", {
  it("returns NULL if empty or no file exclusions", {
    withr::with_options(list(covr.covrignore = ""),
      expect_equal(parse_covr_ignore(), NULL)
      )
    withr::with_envvar(list("COVR_COVRIGNORE" = ""),
      expect_equal(parse_covr_ignore(), NULL)
      )
    tf <- tempfile()
    on.exit(unlink(tf))
    writeLines("", tf)
    withr::with_options(list(covr.covrignore = tf),
      expect_equal(parse_covr_ignore(), NULL)
      )
    withr::with_envvar(list("COVR_COVRIGNORE" = tf),
      expect_equal(parse_covr_ignore(), NULL)
      )
    })
  it("returns the file if file exists", {
    td <- tempfile()
    on.exit(unlink(td, recursive = TRUE))
    dir.create(td)
    writeLines("foo.c", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "foo.c"))
    withr::with_dir(td, {
      expect_equal(parse_covr_ignore(), "foo.c")
    })
  })
  it("handles globs correctly", {
    td <- tempfile()
    on.exit(unlink(td, recursive = TRUE))
    dir.create(td)
    writeLines("foo.*", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "foo.c"))
    writeLines("", file.path(td, "foo.o"))
    withr::with_dir(td, {
      expect_equal(parse_covr_ignore(), c("foo.c", "foo.o"))
    })
  })
  it("handles directories correctly", {
    td <- tempfile()
    on.exit(unlink(td, recursive = TRUE))
    dir.create(td)
    dir.create(file.path(td, "src"))
    writeLines("src", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "src", "foo.c"))
    writeLines("", file.path(td, "src", "foo.o"))
    withr::with_dir(td, {
      expect_equal(gsub("//", "/", parse_covr_ignore()), c("src/foo.c", "src/foo.o"))
    })
  })
})
