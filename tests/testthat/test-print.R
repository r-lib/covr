test_that("format_percentage works as expected", {
  expect_equal(format_percentage(0), cli::col_red("0.00%"))

  expect_equal(format_percentage(25), cli::col_red("25.00%"))

  expect_equal(format_percentage(51), cli::col_red("51.00%"))

  expect_equal(format_percentage(76.5), cli::col_yellow("76.50%"))

  expect_equal(format_percentage(86.5), cli::col_yellow("86.50%"))

  expect_equal(format_percentage(96.5), cli::col_green("96.50%"))

  expect_equal(format_percentage(75), cli::col_yellow("75.00%"))

  expect_equal(format_percentage(90), cli::col_green("90.00%"))
})

test_that("format_percentage uses covr.report_colors (#529)", {
  withr::local_options(
    cli.num_colors = 256,
    covr.report_colors = c(covered = "#0072B2", missed = "#E69F00")
  )
  covered <- cli::make_ansi_style("#0072B2")
  missed <- cli::make_ansi_style("#E69F00")
  expect_equal(format_percentage(96.5), covered("96.50%"))
  expect_equal(format_percentage(76.5), covered("76.50%"))
  expect_equal(format_percentage(51), missed("51.00%"))

  withr::local_options(covr.report_colors = c(missed = "#E69F00"))
  expect_equal(format_percentage(96.5), cli::col_green("96.50%"))
  expect_equal(format_percentage(76.5), cli::col_yellow("76.50%"))
  expect_equal(format_percentage(51), missed("51.00%"))

  withr::local_options(
    covr.report_colors = c(covered = "#0072B2", partial = "#56B4E9")
  )
  expect_equal(format_percentage(96.5), covered("96.50%"))
  expect_equal(
    format_percentage(76.5),
    cli::make_ansi_style("#56B4E9")("76.50%")
  )
  expect_equal(format_percentage(51), cli::col_red("51.00%"))
})

test_that("an invalid covr.report_colors only warns in the console (#529)", {
  withr::local_options(covr.report_colors = c(covered = "notacolor"))
  expect_snapshot(styles <- console_styles())
  expect_equal(styles$high("90.00%"), cli::col_green("90.00%"))
})

test_that("print.coverage prints by = \"line\" by default", {
  cov <- package_coverage(test_path("TestPrint"))

  expect_message(
    print(cov, by = "expression"),
    rex::rex("R/TestPrint.R: ", anything, "66.67%")
  )

  expect_message(
    print(cov, by = "line"),
    rex::rex("TestPrint Coverage: ", anything, "0.00%")
  )

  expect_message(
    print(cov, by = "line"),
    rex::rex("R/TestPrint.R: ", anything, "0.00%")
  )

  # test default
  expect_message(
    print(cov),
    rex::rex("TestPrint Coverage: ", anything, "0.00%")
  )

  expect_message(print(cov), rex::rex("R/TestPrint.R: ", anything, "0.00%"))

  expect_message(
    print(cov, group = "functions"),
    rex::rex("test_me", anything, "0.00%")
  )

  expect_message(
    print(cov, group = "functions", by = "expression"),
    rex::rex("test_me", anything, "66.67%")
  )
})

test_that("print.coverage limits the files or functions printed with n", {
  cov <- code_coverage(
    "f <- function(x) x + 1\ng <- function(x) x - 1\nh <- function(x) 0",
    "f(1)"
  )
  attr(cov, "package") <- list(package = "pkg")

  expect_snapshot({
    print(cov, group = "functions", n = 1)
    print(cov, group = "functions", n = 3)
    print(cov, n = 0)
  })
})

test_that("print.coverage prints nothing for empty coverage", {
  expect_silent(res <- print(structure(list(), class = "coverage")))
  expect_null(res)

  # compiled code has no functions, so there is nothing to tally by function
  cov <- code_coverage("f <- function() 1", "f()")
  cov[[1]]$functions <- NA_character_
  expect_silent(res <- print(cov, by = "function"))
  expect_null(res)
})

test_that("print.coverages prints the coverage of each type", {
  cov <- code_coverage("f <- function() 1", "f()")
  attr(cov, "package") <- list(package = "pkg")
  covs <- structure(
    list(
      tests = structure(cov, type = "tests"),
      examples = structure(cov, type = "examples")
    ),
    package = list(package = "pkg"),
    class = "coverages"
  )

  expect_snapshot(
    res <- print(covs),
    transform = function(x) sub("^[^ ]*source\\.R\\w*", "<file>", x)
  )
  expect_identical(res, covs)
})

test_that("print.coverage lists the missed ranges with missing = TRUE", {
  cov <- code_coverage(
    paste(
      "f <- function(x) {",
      "  if (x) {",
      "    a <- 1",
      "",
      "    # a comment",
      "    b <- 2",
      "  }",
      "  c <- 3",
      "  if (x) {",
      "    d <- 4",
      "  }",
      "}",
      "g <- function(x) {",
      "  e <- 5",
      "}",
      "h <- function(x) x",
      sep = "\n"
    ),
    "f(FALSE); h(1)"
  )
  attr(cov, "package") <- list(package = "pkg")

  expect_snapshot(
    {
      print(cov, missing = TRUE)
      print(cov, group = "functions", missing = TRUE)
      print(cov, missing = FALSE)
      print(cov, by = "expression", missing = TRUE)
    },
    transform = function(x) sub("^.*source\\.R[0-9a-f]+:", "source.R:", x)
  )
})

test_that("print.coverage lists the missed branches with missing = TRUE", {
  withr::local_options(covr.branch_coverage = TRUE)
  cov <- code_coverage(
    paste(
      "f <- function(x) {",
      "  if (x) 1 else 2",
      "  if (x) 3",
      "}",
      "g <- function(x) {",
      "  switch(x, a = 1, b = 2)",
      "}",
      "h <- function(x) {",
      "  if (x) 1 else 2",
      "}",
      sep = "\n"
    ),
    "f(TRUE); g('a')"
  )
  attr(cov, "package") <- list(package = "pkg")

  expect_snapshot(
    {
      print(cov, missing = TRUE)
      print(cov, group = "functions", missing = TRUE)
      print(cov)
    },
    transform = function(x) sub("^.*source\\.R[0-9a-f]+:", "source.R:", x)
  )
})

test_that("evaluated_missed_branches drops constructs that never ran", {
  df <- data.frame(
    filename = "a.R",
    line = c(1, 1, 5, 5),
    column = 3,
    value = c(0, 0, 2, 0)
  )
  expect_equal(evaluated_missed_branches(df), df[4, ])
})

test_that("format_branches orders the branches by line", {
  df <- data.frame(
    line = c(30, 12, 12),
    branch = c(2, 2, 1),
    label = c("b", "FALSE", "TRUE")
  )
  expect_equal(format_branches(df), "12 TRUE, 12 FALSE, 30 b")
})

test_that("print.coverage caps the missed ranges and branches per row", {
  withr::local_options(covr.branch_coverage = TRUE)
  fns <- vapply(
    1:14,
    function(i) {
      sprintf(
        "f%d <- function(x) {\n  if (x) 1 else 2\n  if (!x) {\n    3\n  }\n}",
        i
      )
    },
    character(1)
  )
  cov <- code_coverage(
    paste(fns, collapse = "\n"),
    paste(sprintf("f%d(TRUE)", 1:14), collapse = "; ")
  )
  attr(cov, "package") <- list(package = "pkg")
  transform <- function(x) sub("^.*source\\.R[0-9a-f]+:", "source.R:", x)

  expect_snapshot(print(cov, missing = TRUE), transform = transform)

  withr::local_options(covr.print_max_ranges = 2)
  expect_snapshot(print(cov, missing = TRUE), transform = transform)

  withr::local_options(covr.print_max_ranges = Inf)
  expect_snapshot(print(cov, missing = TRUE), transform = transform)
})

test_that("cap_items() keeps the first items and counts the rest", {
  expect_equal(cap_items(c("a", "b", "c"), 2), "a, b, ... (1 more)")
  expect_equal(cap_items(c("a", "b"), 2), "a, b")
  expect_equal(cap_items(letters, Inf), paste(letters, collapse = ", "))
  expect_equal(cap_items(character()), "")
})
