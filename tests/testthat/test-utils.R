test_that("it throws error if no package", {
  expect_error(as_package("arst11234"), "must be an existing directory")
})

test_that("it returns the package if given the root or child directory", {
  expect_equal(as_package("TestS4")$package, "TestS4")
  expect_equal(as_package("TestS4/")$package, "TestS4")

  expect_equal(as_package("TestS4/R")$package, "TestS4")

  expect_equal(as_package("TestS4/tests")$package, "TestS4")

  expect_equal(as_package("TestS4/tests/testthat")$package, "TestS4")
})

test_that("it works as expected", {
  with_mocked_bindings(
    system_output = function(...) {
      "test_branch "
    },
    expect_equal(local_branch("TestSummary"), "test_branch")
  )
})

test_that("it works as expected", {
  with_mocked_bindings(
    system_output = function(...) {
      " test_hash"
    },
    expect_equal(current_commit("TestSummary"), "test_hash")
  )
})

test_that("per_line removes blank lines and lines with only punctuation (#387)", {
  skip_on_cran()

  cov <- package_coverage(test_path("TestFunctional"))

  line_cov <- per_line(cov)

  expect_equal(
    line_cov[[1]]$coverage,
    c(NA, 0, 0, 2, NA, 1, NA, 1, NA, NA, NA, NA, NA, NA, NA, NA, NA)
  )
})

test_that("per_line counts lines as tally_coverage does (#620)", {
  cov <- shared_line_coverage()

  expect_equal(per_line(cov)[[1]]$coverage, c(NA, 1, 0, NA, NA, 0))

  stats <- to_report_data(cov)$file_stats
  expect_equal(stats$Relevant, 3)
  expect_equal(stats$Covered, 1)
})

test_that("split_on_line_directives returns NULL for input without directive (#588)", {
  expect_identical(
    split_on_line_directives(NULL),
    NULL
  )
  expect_identical(
    split_on_line_directives(character()),
    NULL
  )
  expect_identical(
    split_on_line_directives("aa"),
    NULL
  )
  expect_identical(
    split_on_line_directives(c("abc", "def")),
    NULL
  )
})

test_that("split_on_line_directives does not simplify the result (#588)", {
  expect_identical(
    split_on_line_directives(
      c(
        '#line 1 "foo.R"',
        "abc",
        "def"
      )
    ),
    list(
      "foo.R" = c("abc", "def")
    )
  )
  expect_identical(
    split_on_line_directives(
      c(
        '#line 1 "foo.R"',
        "abc",
        "def",
        '#line 4 "bar.R"',
        "ghi",
        "jkl"
      )
    ),
    list(
      "foo.R" = c("abc", "def"),
      "bar.R" = c("ghi", "jkl")
    )
  )
})

test_that("split_on_line_directives handles empty files (#522)", {
  expect_identical(
    split_on_line_directives(
      c(
        '#line 1 "empty1.R"',
        '#line 1 "foo.R"',
        "abc",
        '#line 1 "empty2.R"',
        '#line 1 "bar.R"',
        "def",
        '#line 1 "empty3.R"'
      )
    ),
    list(
      "empty1.R" = character(),
      "foo.R" = "abc",
      "empty2.R" = character(),
      "bar.R" = "def",
      "empty3.R" = character()
    )
  )
})

test_that("as_package() errors if the path isn't in a package", {
  dir <- withr::local_tempdir()

  expect_error(as_package(dir), "Can't find a package in")
})

test_that("package_root() returns NULL outside of a package", {
  expect_null(package_root(withr::local_tempdir()))
  expect_equal(package_root("TestS4/R"), normalize_path("TestS4"))
})

test_that("get_package_name() uses the package of the coverage, or a default", {
  expect_equal(
    get_package_name(structure(list(), package = list(package = "pkg"))),
    "pkg"
  )
  expect_equal(get_package_name(list()), "coverage")
})

test_that("inactive_names() and eapply_inactive() skip active bindings", {
  env <- new.env()
  makeActiveBinding("ab", function() stop("boom"), env)
  assign("x", 1, env)
  assign(".y", 2, env)

  expect_equal(inactive_names(env), c(".y", "x"))
  expect_equal(eapply_inactive(env, identity), list(.y = 2, x = 1))
})
