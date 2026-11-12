test_that("it returns an empty vector if there are no exclusions", {
  t1 <- c("this", "is", "a", "test")
  expect_equal(
    do.call(parse_exclusions, c(list(t1), exclude_ops, recursive = F)),
    numeric(0)
  )
})

test_that("it returns the line if one line is excluded", {
  t1 <- c("this", "is #TeSt_NoLiNt", "a", "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(2))

  t2 <- c("this", "is #TeSt_NoLiNt", "a", "test #TeSt_NoLiNt")
  expect_equal(do.call(parse_exclusions, c(list(t2), exclude_ops)), c(2, 4))
})

test_that("it returns all lines between start and end", {
  t1 <- c("this #TeSt_NoLiNt_StArT", "is", "a #TeSt_NoLiNt_EnD", "test")
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(1, 2, 3))

  t2 <- c(
    "this #TeSt_NoLiNt_StArT",
    "is",
    "a #TeSt_NoLiNt_EnD",
    "test",
    "of",
    "the #TeSt_NoLiNt_StArT",
    "emergency #TeSt_NoLiNt_EnD",
    "broadcast",
    "system"
  )
  expect_equal(
    do.call(parse_exclusions, c(list(t2), exclude_ops)),
    c(1, 2, 3, 6, 7)
  )
})

test_that("it ignores exclude coverage lines within start and end", {
  t1 <- c(
    "this #TeSt_NoLiNt_StArT",
    "is #TeSt_NoLiNt",
    "a #TeSt_NoLiNt_EnD",
    "test"
  )
  expect_equal(do.call(parse_exclusions, c(list(t1), exclude_ops)), c(1, 2, 3))
})

test_that("it throws an error if start and end are unpaired", {
  t1 <- c("this #TeSt_NoLiNt_StArT", "is #TeSt_NoLiNt", "a", "test")
  expect_snapshot(
    do.call(parse_exclusions, c(list(t1), exclude_ops)),
    error = TRUE
  )
  expect_snapshot(
    do.call(parse_exclusions, c(list(t1), exclude_ops, file = "R/foo.R")),
    error = TRUE
  )

  t2 <- c(
    "this #TeSt_NoLiNt_StArT",
    "is #TeSt_NoLiNt_EnD",
    "a #TeSt_NoLiNt_EnD",
    "test"
  )
  expect_snapshot(
    do.call(parse_exclusions, c(list(t2), exclude_ops, file = "R/foo.R")),
    error = TRUE
  )
})

test_that("unpaired start and end errors give the file name", {
  f <- withr::local_tempfile(
    fileext = ".R",
    lines = c("f <- function(x) { # nocov start", "  x", "} # nocov start")
  )
  expect_snapshot(
    file_coverage(f, character()),
    error = TRUE,
    transform = function(x) gsub(f, "<file>", x, fixed = TRUE)
  )
})

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

  expect_equal_vals(
    normalize_exclusions(list("a", b = 1)),
    list(a = Inf, b = 1)
  )
})

test_that("it handles redundant lines", {
  expect_equal_vals(
    normalize_exclusions(list(a = c(1, 1, 1:10))),
    list(a = 1:10)
  )

  expect_equal_vals(
    normalize_exclusions(list(a = c(1, 1, 1:10), b = 1:10)),
    list(a = 1:10, b = 1:10)
  )
})

test_that("it handles redundant files", {
  expect_equal_vals(
    normalize_exclusions(list(a = c(1:10), a = c(10:20))),
    list(a = 1:20)
  )
})

test_that("exclude() excludes lines and functions, and preserves the class", {
  cov <- package_coverage("TestSummary")
  expect_equal(length(cov), 4)
  expect_equal(
    length(exclude(cov, list("R/TestSummary.R" = 5), path = "TestSummary")),
    3
  )
  expect_equal(
    length(exclude(cov, list("R/TestSummary.R" = 13), path = "TestSummary")),
    3
  )

  expect_equal(class(exclude(cov, NULL, path = "TestSummary")), class(cov))
  expect_equal(
    class(exclude(cov, list("R/TestSummary.R" = 3), path = "TestSummary")),
    class(cov)
  )

  expect_equal(length(exclude(cov, NULL, "^test")), 1)
  expect_equal(length(exclude(cov, NULL, c("^test", "dont"))), 0)
})

test_that("it excludes properly", {
  t1 <- package_coverage("TestExclusion")

  expect_equal(length(t1), 3)

  t1 <- package_coverage("TestExclusion", line_exclusions = "R/TestExclusion.R")

  expect_equal(length(t1), 0)
})

test_that("excluded lines of a multi-line expression are not counted (#594)", {
  src <- paste(
    "maker <- function(fun) {",
    "  function(x) { # nocov",
    "    fun(x)",
    "  } # nocov",
    "}",
    "f <- maker(identity)",
    sep = "\n"
  )
  cov <- code_coverage(src, "f(1)")

  expect_equal(tally_coverage(cov)$line, 3)
  expect_equal(per_line(cov)[[1]]$coverage, c(NA, NA, 1, NA, NA, NA))
})


describe("covrignore", {
  it("returns NULL if empty or no file exclusions", {
    withr::with_options(
      list(covr.covrignore = ""),
      expect_equal(parse_covr_ignore(), NULL)
    )
    withr::with_envvar(
      list("COVR_COVRIGNORE" = ""),
      expect_equal(parse_covr_ignore(), NULL)
    )
    tf <- withr::local_tempfile()
    writeLines("", tf)
    withr::with_options(
      list(covr.covrignore = tf),
      expect_equal(parse_covr_ignore(), NULL)
    )
    withr::with_envvar(
      list("COVR_COVRIGNORE" = tf),
      expect_equal(parse_covr_ignore(), NULL)
    )
  })
  it("reads the option, then the environment variable, then .covrignore", {
    td <- withr::local_tempdir()
    writeLines("from-default.c", file.path(td, ".covrignore"))
    writeLines("from-env.c", file.path(td, "env-ignore"))
    writeLines("from-option.c", file.path(td, "option-ignore"))
    for (file in c("from-default.c", "from-env.c", "from-option.c")) {
      writeLines("", file.path(td, file))
    }
    withr::local_dir(td)
    withr::local_options(covr.covrignore = NULL)
    withr::local_envvar(COVR_COVRIGNORE = NA)
    expect_equal(parse_covr_ignore(), "from-default.c")

    withr::local_envvar(COVR_COVRIGNORE = "env-ignore")
    expect_equal(parse_covr_ignore(), "from-env.c")

    withr::local_options(covr.covrignore = "option-ignore")
    expect_equal(parse_covr_ignore(), "from-option.c")
  })
  it("returns the file if file exists", {
    td <- withr::local_tempdir()
    writeLines("foo.c", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "foo.c"))
    withr::with_dir(td, {
      expect_equal(parse_covr_ignore(), "foo.c")
    })
  })
  it("handles globs correctly", {
    td <- withr::local_tempdir()
    writeLines("foo.*", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "foo.c"))
    writeLines("", file.path(td, "foo.o"))
    withr::with_dir(td, {
      expect_equal(parse_covr_ignore(), c("foo.c", "foo.o"))
    })
  })
  it("handles directories correctly", {
    td <- withr::local_tempdir()
    dir.create(file.path(td, "src"))
    writeLines("src", file.path(td, ".covrignore"))
    writeLines("", file.path(td, "src", "foo.c"))
    writeLines("", file.path(td, "src", "foo.o"))
    withr::with_dir(td, {
      expect_equal(
        gsub("//", "/", parse_covr_ignore()),
        c("src/foo.c", "src/foo.o")
      )
    })
  })
})

test_that("excluding the first line of an `if` or `switch()` excludes its branches", {
  cov <- branch_coverage(
    c(
      "f <- function(x) {",
      "  if (x) 'yes' # nocov",
      "  if (!x) 'no'",
      "  # nocov start",
      "  switch(x,",
      "    a = 1",
      "  )",
      "  # nocov end",
      "}",
      "g <- function(x) if (x) 1"
    ),
    "f(TRUE); g(TRUE)"
  )
  res <- tally_coverage(cov, by = "branch")
  expect_equal(res$line, c(3, 3, 10, 10))

  res <- tally_coverage(
    exclude(cov, function_exclusions = "^g$"),
    by = "branch"
  )
  expect_equal(res$line, c(3, 3))
})

test_that("unnamed full file exclusions must be single strings", {
  expect_snapshot(normalize_exclusions(list("a", b = 1, 1:2)), error = TRUE)
  expect_snapshot(
    normalize_exclusions(list(a = 1, 2, c("b", "c"))),
    error = TRUE
  )
})
