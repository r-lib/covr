context("print function")
op <- options()
on.exit(options(op))
options(crayon.enabled = TRUE)

test_that("format_percentage works as expected", {
  expect_equal(format_percentage(0), "\u001b[31m0.00%\u001b[39m")

  expect_equal(format_percentage(0.25), "\u001b[31m25.00%\u001b[39m")

  expect_equal(format_percentage(0.51), "\u001b[31m51.00%\u001b[39m")

  expect_equal(format_percentage(0.765), "\u001b[33m76.50%\u001b[39m")

  expect_equal(format_percentage(0.865), "\u001b[33m86.50%\u001b[39m")

  expect_equal(format_percentage(0.965), "\u001b[32m96.50%\u001b[39m")
})

test_that("print.coverage works as expected", {
  cov <- structure(list(
      `file:1:1:1:1:1:1:1:1` = 0,
      `file:1:1:1:1:1:1:1:1` = 1
      ),
    class = "coverage")

  expect_message(print(cov),
    rex::rex("Package Coverage: ", anything, "50.00%"))

  expect_message(print(cov),
    rex::rex("file: ", anything, "50.00%"))

})
test_that("print.coverage only displays Package Coverage if all files are covered completely", {
  cov <- structure(list(
      `file:1:1:1:1:1:1:1:1` = 1,
      `file2:1:1:1:1:1:1:1:1` = 1
      ),
    class = "coverage")

  expect_message(print(cov),
    rex::rex("Package Coverage: ", anything, "100.00%"), all = TRUE)
})
