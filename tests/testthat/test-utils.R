context("as_package")
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

context("local_branch")
test_that("it works as expected", {
  with_mock(`covr:::system_output` = function(...) { "test_branch " }, {
    expect_equal(local_branch("TestSummary"), "test_branch")
  })
})

context("current_commit")
test_that("it works as expected", {
  with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
  expect_equal(current_commit("TestSummary"), "test_hash")
  })
})

context("get_source_filename")
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

  cov <- package_coverage(test_path("testFunctional"))

  line_cov <- per_line(cov)

  expect_equal(line_cov[[1]]$coverage, c(NA, 0, 0, 2, NA, 1, NA, 1, NA, NA, NA, NA, NA, NA, NA, NA, NA))
})
