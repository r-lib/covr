test_that("it throws error if no package", {
  expect_error(as_package("arst11234"), "`path` is invalid:.*arst11234")
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
    system_output = function(...) {"test_branch "},
    expect_equal(local_branch("TestSummary"), "test_branch")
  )
})

test_that("it works as expected", {
  with_mocked_bindings(
    system_output = function(...) {" test_hash"},
    expect_equal(current_commit("TestSummary"), "test_hash")
  )
})

test_that("it works", {
  # R 4.0.0 changes this behavior so `getSrcFilename()` will actually return
  # "test-utils.R"

  skip_if(getRversion() >= "4.0.0")

  x <- eval(bquote(function() 1))

  expect_identical(getSrcFilename(x), character())
  expect_identical(get_source_filename(x), "")
})

test_that("per_line removes blank lines and lines with only punctuation (#387)", {
  skip_on_cran()

  cov <- package_coverage(test_path("TestFunctional"))

  line_cov <- per_line(cov)

  expect_equal(line_cov[[1]]$coverage, c(NA, 0, 0, 2, NA, 1, NA, 1, NA, NA, NA, NA, NA, NA, NA, NA, NA))
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
