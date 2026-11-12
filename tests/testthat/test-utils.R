test_that("it throws error if no package", {
  expect_snapshot(as_package("arst11234"), error = TRUE)
})

test_that("it returns the package if given the root or child directory", {
  expect_equal(as_package("TestS4")$package, "TestS4")
  expect_equal(as_package("TestS4/")$package, "TestS4")

  expect_equal(as_package("TestS4/R")$package, "TestS4")

  expect_equal(as_package("TestS4/tests")$package, "TestS4")

  expect_equal(as_package("TestS4/tests/testthat")$package, "TestS4")
})

test_that("local_branch() trims the output of git", {
  with_mocked_bindings(
    system_output = function(...) {
      "test_branch "
    },
    expect_equal(local_branch("TestSummary"), "test_branch")
  )
})

test_that("current_commit() trims the output of git", {
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

  expect_snapshot(
    as_package(dir),
    error = TRUE,
    transform = function(x) gsub(normalize_path(dir), "<dir>", x, fixed = TRUE)
  )
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

test_that("traced_files skips traces without a source file", {
  ref <- parse_srcrefs("x <- 1")$refs[[1]]
  cov <- structure(
    list(
      a = list(srcref = NULL, value = 1),
      b = list(srcref = ref, value = 1),
      c = list(srcref = ref, value = 1)
    ),
    class = "coverage"
  )
  expect_named(traced_files(cov), "<text>")
})

test_that("read_description errors if there is no DESCRIPTION file", {
  expect_snapshot(read_description("no-such-dir/DESCRIPTION"), error = TRUE)
})

test_that("normalize_path() strips trailing slashes but keeps roots", {
  dir <- withr::local_tempdir()
  expect_equal(normalize_path(paste0(dir, "//")), normalize_path(dir))
  expect_match(normalize_path("/"), "^([A-Za-z]:)?/$")
  expect_equal(normalize_path("C:/"), "C:/")
  expect_equal(normalize_path("C:/foo/"), "C:/foo")
  expect_equal(normalize_path(c("/", NA)), c(normalize_path("/"), NA))
})

test_that("normalize_path() keeps a root of slashes", {
  skip_on_os("windows")
  expect_equal(normalize_path("//"), "/")
})

test_that("package_root() stops at the filesystem root", {
  expect_null(package_root("/"))
})

test_that("logical_setting() reads the option, then the environment variable", {
  setting <- function(default = NA) {
    logical_setting("covr.test_setting", "COVR_TEST_SETTING", default)
  }
  withr::local_options(covr.test_setting = NULL)
  withr::local_envvar(COVR_TEST_SETTING = NA)
  expect_true(setting(TRUE))
  expect_false(setting(FALSE))

  withr::local_envvar(COVR_TEST_SETTING = "")
  expect_true(setting(TRUE))

  withr::local_envvar(COVR_TEST_SETTING = "No")
  expect_false(setting(TRUE))

  withr::local_options(covr.test_setting = TRUE)
  expect_true(setting(FALSE))

  withr::local_options(covr.test_setting = FALSE)
  withr::local_envvar(COVR_TEST_SETTING = "true")
  expect_false(setting(TRUE))
})

test_that("logical_setting() accepts true and false spellings in any case", {
  setting <- function() {
    logical_setting("covr.test_setting", "COVR_TEST_SETTING", NA)
  }
  withr::local_options(covr.test_setting = NULL)
  for (value in c("true", "T", "Yes", "1", " TRUE ")) {
    withr::local_envvar(COVR_TEST_SETTING = value)
    expect_true(setting())
  }
  for (value in c("false", "F", "NO", "0")) {
    withr::local_envvar(COVR_TEST_SETTING = value)
    expect_false(setting())
  }
  withr::local_envvar(COVR_TEST_SETTING = NA)
  for (value in list("TRUE", "no", 1, 0, "f")) {
    withr::local_options(covr.test_setting = value)
    expect_identical(setting(), parse_logical(value))
  }
})

test_that("logical_setting() warns about and ignores invalid values", {
  setting <- function(default = TRUE) {
    logical_setting("covr.test_setting", "COVR_TEST_SETTING", default)
  }
  withr::local_options(covr.test_setting = NULL)
  withr::local_envvar(COVR_TEST_SETTING = "maybe")
  expect_snapshot(expect_true(setting()))
  expect_snapshot(expect_false(setting(FALSE)))

  withr::local_options(covr.test_setting = c(TRUE, FALSE))
  withr::local_envvar(COVR_TEST_SETTING = "no")
  expect_snapshot(expect_false(setting()))
})

test_that("string_setting() reads the option, then the environment variable", {
  setting <- function() {
    string_setting("covr.test_setting", "COVR_TEST_SETTING", "default")
  }
  withr::local_options(covr.test_setting = NULL)
  withr::local_envvar(COVR_TEST_SETTING = NA)
  expect_equal(setting(), "default")

  withr::local_envvar(COVR_TEST_SETTING = "env")
  expect_equal(setting(), "env")

  withr::local_options(covr.test_setting = "option")
  expect_equal(setting(), "option")
})
