test_that("covr_error keeps full output and a bounded message", {
  skip_if_not(l10n_info()$`UTF-8`)
  td <- withr::local_tempdir()
  out <- file.path(td, "test.Rout.fail")
  body <- paste0("\u2714 line ", 1:200, " \u2550\u2550")
  # multibyte body where bytes - warning.length exceeds nchar (old bug)
  writeLines(
    enc2utf8(c("R version header", "more header", ">", body)),
    out,
    useBytes = TRUE
  )
  expect_gt(sum(nchar(body, "bytes")) - 300, sum(nchar(body, "chars")))

  withr::local_options(warning.length = 300)
  err <- expect_error(show_failures(td), class = "covr_error")
  expect_equal(err$file, out)
  # header skipped, whole output kept
  expect_equal(err$output, c(">", body))
  msg <- conditionMessage(err)
  expect_lte(nchar(msg, "chars"), 300 - 9)
  expect_match(msg, "line 200", fixed = TRUE)
  expect_no_match(msg, "line 1 ", fixed = TRUE)
  expect_no_match(msg, "R version header", fixed = TRUE)
})

test_that("covr_error message is capped at the default number of lines", {
  withr::local_options(warning.length = 8170)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(grep("^line ", msg, value = TRUE), paste0("line ", 71:120))
  expect_length(err$output, 121)
})

test_that("covr.failure_lines sets the number of lines in the message and print", {
  withr::local_options(warning.length = 8170, covr.failure_lines = 5)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(grep("^line ", msg, value = TRUE), paste0("line ", 116:120))
  expect_equal(
    utils::tail(strsplit(format(err), "\n")[[1]], 5),
    paste0("line ", 116:120)
  )
})

test_that("covr_error print shows the last n lines", {
  err <- covr_error_for(paste0("line ", 1:10))
  expect_snapshot({
    print(err, n = 3)
    print(err, n = Inf)
  })
})

test_that("show_failures handles output without a prompt", {
  err <- covr_error_for(c("a", "b"), prompt = FALSE)
  expect_equal(err$output, c("a", "b"))
})

test_that("covr_error message is only the header if warning.length is too small", {
  withr::local_options(warning.length = 100)
  err <- covr_error_for(paste0("line ", 1:3))
  msg <- conditionMessage(err)
  expect_match(msg, "Code run to compute coverage failed", fixed = TRUE)
  expect_no_match(msg, "line", fixed = TRUE)
  expect_length(err$output, 4)
})

test_that("covr_error truncates a single line that is too long", {
  withr::local_options(warning.length = 250)
  err <- covr_error_for(paste0(strrep("a", 500), "END"))
  msg <- conditionMessage(err)
  expect_lte(nchar(msg), 250 - 9)
  expect_match(msg, "\na+END$")
  expect_equal(nchar(err$output[[2]]), 503)
})
