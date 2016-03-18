context("as_package")
test_that("it throws error if no package", {
  expect_error(as_package("arst11234"), "does not contain a package!")
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
  expect_equal(local_branch("TestSummary"), "master")
}
context("current_commit")
test_that("it works as expected", {
  expect_equal(current_commit("TestSummary"), "4b45ba2eb12b955a96c4783308345bf446292ce2")
}
