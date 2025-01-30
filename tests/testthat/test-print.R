test_that("format_percentage works as expected", {
  expect_equal(format_percentage(0), cli::col_red("0.00%"))

  expect_equal(format_percentage(25), cli::col_red("25.00%"))

  expect_equal(format_percentage(51), cli::col_red("51.00%"))

  expect_equal(format_percentage(76.5), cli::col_yellow("76.50%"))

  expect_equal(format_percentage(86.5), cli::col_yellow("86.50%"))

  expect_equal(format_percentage(96.5), cli::col_green("96.50%"))
})

test_that("print.coverage prints by = \"line\" by default", {
  cov <- package_coverage(test_path("TestPrint"))

  expect_message(print(cov, by = "expression"),
    rex::rex("R/TestPrint.R: ", anything, "66.67%"))

  expect_message(print(cov, by = "line"),
    rex::rex("TestPrint Coverage: ", anything, "0.00%"))

  expect_message(print(cov, by = "line"),
    rex::rex("R/TestPrint.R: ", anything, "0.00%"))

  # test default
  expect_message(print(cov),
    rex::rex("TestPrint Coverage: ", anything, "0.00%"))

  expect_message(print(cov),
    rex::rex("R/TestPrint.R: ", anything, "0.00%"))

  expect_message(print(cov, group = "functions"),
    rex::rex("test_me", anything, "0.00%"))

  expect_message(print(cov, group = "functions", by = "expression"),
    rex::rex("test_me", anything, "66.67%"))
})
