context("test_directory")
test_that("it returns tests if it exists", {
  with_mock(file.exists = function(x) x == "./tests",
    expect_equal(test_directory("."), "./tests")
  )
})
test_that("it returns inst/tests if it exists", {
  with_mock(file.exists = function(x) x == "./inst/tests",
    expect_equal(test_directory("."), "./inst/tests")
  )
})
test_that("it returns tests if it and inst/tests exists", {
  with_mock(file.exists = function(x) x == "./inst/tests" | x == "./tests",
    expect_equal(test_directory("."), "./tests")
  )
})
test_that("it errors if tests and inst/tests don't exist", {
  with_mock(file.exists = function(x) FALSE,
    expect_error(test_directory("."), "No testing directory found")
  )
})
