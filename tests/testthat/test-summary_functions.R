test_that("Summary gives 50% coverage and two lines with zero coverage", {
  cv <- package_coverage(test_path("TestSummary"))
  expect_equal(percent_coverage(cv), 50)
  expect_equal(nrow(zero_coverage(cv)), 2)
})

test_that("tally_coverage() and zero_coverage() by function", {
  cov <- code_coverage(
    paste(
      "f <- function(x) {",
      "  if (x) {",
      "    1",
      "  } else {",
      "    2",
      "  }",
      "}",
      "g <- function() {",
      "  h <- function() 3",
      "  h()",
      "}",
      "k <- function() {",
      "  4",
      "}",
      sep = "\n"
    ),
    "f(TRUE); f(TRUE); g()"
  )

  res <- tally_coverage(cov, by = "function")
  expect_named(
    res,
    c("filename", "functions", "first_line", "last_line", "value")
  )
  expect_equal(res$functions, c("f", "g", "k"))
  expect_equal(res$first_line, c(2, 9, 13))
  expect_equal(res$last_line, c(5, 10, 13))
  expect_equal(res$value, c(2, 1, 0))

  expect_equal(zero_coverage(cov, by = "function")$functions, "k")
  expect_equal(percent_coverage(cov, by = "function"), 200 / 3)
})

test_that("percent_coverage", {
  old <- getOption("keep.source")
  options(keep.source = TRUE)
  on.exit(options(keep.source = old), add = TRUE)

  fun <- function() {
    x <- 1
    if (x > 2) {
      print(x)
    }
    res <- lapply(1:2, function(x) {
      x + 1
    })
  }
  cov <- function_coverage("fun", env = environment(fun), fun())

  res <- percent_coverage(cov)
  expect_equal(res, 80)
})

test_that("a line is only covered if all its expressions ran (#620)", {
  cov <- shared_line_coverage()

  res <- tally_coverage(cov)
  expect_equal(res$line, c(2, 3, 6, 6))
  expect_equal(res$value, c(1, 0, 1, 0))

  expect_equal(percent_coverage(cov), 100 / 3)
  expect_equal(coverage_to_list(cov)$totalcoverage, 33.33)
  expect_equal(as.vector(coverage_to_list(cov)$filecoverage), 33.33)
  expect_equal(unclass(coverage_to_markdown(cov))[[3]], "| Total | 33.33% |")
})

test_that("tally_coverage() is fast with thousands of expressions on a line (#620)", {
  skip_on_cran()
  n <- 2000
  df <- data.frame(
    filename = "a.R",
    functions = "f",
    first_line = c(1, rep(2, n)),
    first_byte = c(1, seq(1, by = 5, length.out = n)),
    last_line = c(3, rep(2, n)),
    last_byte = c(10, seq(4, by = 5, length.out = n)),
    value = c(1, rep(2, n - 1), 0),
    stringsAsFactors = FALSE
  )

  time <- system.time(res <- tally_coverage(df))[["elapsed"]]
  expect_lt(time, 2)
  expect_equal(res$value, c(1, 0, 1))
})

test_that("coverage_to_markdown() formats totals, files and differences", {
  src <- "f <- function(x) {\n  if (x) {\n    1\n  }\n  2\n}"
  dir <- withr::local_tempdir()
  writeLines(src, file.path(dir, "f.R"))
  writeLines("f(TRUE)", file.path(dir, "full.R"))
  writeLines("f(FALSE)", file.path(dir, "part.R"))
  withr::local_dir(dir)
  full <- file_coverage("f.R", "full.R")
  part <- file_coverage("f.R", "part.R")
  expect_snapshot(
    {
      coverage_to_markdown(part)
      coverage_to_markdown(full, base = part)
    }
  )
})

test_that("coverage_to_markdown() escapes file names and handles missing/lower base", {
  skip_on_os("windows")
  src <- "f <- function(x) {\n  if (x) {\n    1\n  }\n  2\n}"
  dir <- withr::local_tempdir()
  writeLines(src, file.path(dir, "a|b<c>.R"))
  writeLines(sub("^f", "g", src), file.path(dir, "new.R"))
  writeLines("f(TRUE)\ng(TRUE)", file.path(dir, "full.R"))
  writeLines("f(FALSE)", file.path(dir, "part.R"))
  withr::local_dir(dir)
  full <- file_coverage(c("a|b<c>.R", "new.R"), "full.R")
  part <- file_coverage("a|b<c>.R", "part.R")
  expect_snapshot({
    coverage_to_markdown(full)
    coverage_to_markdown(full, base = part)
    coverage_to_markdown(part, base = full)
  })
})

test_that("tally_coverage() ignores expressions without source lines", {
  cov <- code_coverage("f <- function() 1\ng <- function() 2", "f()")
  df <- as.data.frame(cov, sort = FALSE)

  df$first_line[df$functions == "f"] <- NA
  res <- tally_coverage(df)
  expect_equal(res$functions, "g")
  expect_equal(res$line, 2)

  df$first_line <- NA
  res <- tally_coverage(df)
  expect_equal(nrow(res), 0)
  expect_named(res, c("filename", "functions", "line", "value"))
})

test_that("zero_coverage() sends the zero coverage to RStudio markers", {
  cov <- code_coverage(
    "f <- function() {\n  1\n}\ng <- function() {\n  2\n}",
    "f()"
  )
  attr(cov, "package") <- list(package = "pkg", path = "/path/to/pkg")

  sent <- NULL
  local_mocked_bindings(
    rstudio_has_source_markers = function() TRUE,
    rstudio_source_markers = function(markers, base_path) {
      sent <<- list(markers = markers, base_path = base_path)
    }
  )

  res <- zero_coverage(cov)
  expect_equal(res$line, 5)
  expect_equal(sent$base_path, "/path/to/pkg")
  expect_length(sent$markers, 1)
  expect_equal(sent$markers[[1]]$type, "warning")
  expect_equal(sent$markers[[1]]$line, 5)
  expect_equal(sent$markers[[1]]$message, "No Test Coverage!")

  # the option turns the markers off
  sent <- NULL
  withr::local_options(covr.rstudio_source_markers = FALSE)
  zero_coverage(cov)
  expect_null(sent)
})

test_that("a function named like a placeholder is not missing", {
  cov <- code_coverage(
    "`___NA___` <- function() 1\ng <- function() 2",
    "`___NA___`()"
  )
  expect_setequal(as.data.frame(cov)$functions, c("___NA___", "g"))
  expect_setequal(
    tally_coverage(cov, by = "function")$functions,
    c("___NA___", "g")
  )

  is_g <- vapply(cov, function(x) identical(x$functions, "g"), logical(1))
  expect_equal(sum(is_g), 1)
  cov[[which(is_g)]]$functions <- NA_character_
  expect_setequal(as.data.frame(cov)$functions, c("___NA___", NA))
})

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

test_that("print.coverage prints braces in function and file names as they are", {
  cov <- code_coverage(
    "`f{x}` <- function() 1\n`g{{y}}` <- function() 2\nh <- function() 3",
    "`f{x}`()"
  )
  attr(cov, "package") <- list(package = "pkg")
  expect_snapshot(print(cov, group = "functions"))

  dir <- withr::local_tempdir()
  source <- file.path(dir, "a{missing}.R")
  writeLines("f <- function() 1", source)
  test <- local_r_file("f()")
  cov <- file_coverage(source, test)
  attr(cov, "package") <- list(package = "pkg")
  expect_snapshot(print(cov), transform = function(x) {
    sub("^.*a\\{missing\\}\\.R:", "a{missing}.R:", x)
  })
})

test_that("print.coverage keeps the rows apart when a long name wraps", {
  withr::local_options(cli.condition_width = 40)
  long <- strrep("a", 50)
  cov <- code_coverage(
    sprintf("%s <- function() 1\ng <- function() 2\nh <- function() 3", long),
    "g()"
  )
  attr(cov, "package") <- list(package = "pkg")

  expect_snapshot(print(cov, group = "functions"))
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

test_that("branch_pieces orders the branches by line", {
  df <- data.frame(
    line = c(30, 12, 12),
    branch = c(2, 2, 1),
    label = c("b", "FALSE", "TRUE")
  )
  expect_equal(branch_pieces(df), c("12 TRUE", "12 FALSE", "30 b"))
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

test_that("print.coverage checks covr.print_max_ranges", {
  cov <- code_coverage("f <- function() 1\ng <- function() 2", "f()")
  withr::local_options(covr.print_max_ranges = "a")
  expect_snapshot(print(cov, missing = TRUE), error = TRUE)
})

test_that("cap_items() keeps the first items and counts the rest", {
  expect_equal(cap_items(c("a", "b", "c"), 2), "a, b, ... (1 more)")
  expect_equal(cap_items(c("a", "b"), 2), "a, b")
  expect_equal(cap_items(letters, Inf), paste(letters, collapse = ", "))
  expect_equal(cap_items(character()), "")
})

test_that("format_messages() and range_pieces() handle no lines", {
  expect_identical(format_messages(character()), character())
  expect_identical(range_pieces(integer()), character())
})
