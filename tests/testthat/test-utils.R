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
