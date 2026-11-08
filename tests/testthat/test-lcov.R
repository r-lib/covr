test_that("it works with coverage objects", {
  tmp <- tempfile(fileext = ".info")
  cov <- package_coverage(test_path("TestSummary"))
  to_lcov(cov, filename = tmp)
  expect_snapshot(writeLines(readLines(tmp)))
})

test_that("large counts are not written in scientific notation", {
  cov <- code_coverage("f <- function() 1", "f()")
  cov[[1]]$value <- 1e5
  out <- to_lcov(cov, tempfile())
  expect_equal(
    grep("^(FNDA|DA):", out, value = TRUE),
    c("FNDA:100000,f", "DA:1,100000")
  )
})

test_that("functions sharing a line give a single line record", {
  cov <- code_coverage("f <- function() 1; g <- function() 2", "f()")
  out <- to_lcov(cov, tempfile())
  expect_equal(
    grep("^(DA|LF|LH):", out, value = TRUE),
    c("DA:1,0", "LF:1", "LH:0")
  )
  expect_equal(grep("^(FNF|FNH):", out, value = TRUE), c("FNF:2", "FNH:1"))
})

test_that("line totals match the line coverage of reports", {
  cov <- code_coverage(
    "f <- function() 1; g <- function() 2\nh <- function() {\n  3\n}\nk <- function() 4",
    "f(); h()"
  )
  out <- to_lcov(cov, tempfile())
  lines <- unlist(lapply(per_line(cov), function(x) x$coverage))
  expect_equal(
    grep("^LF:", out, value = TRUE),
    paste0("LF:", sum(!is.na(lines)))
  )
  expect_equal(
    grep("^LH:", out, value = TRUE),
    paste0("LH:", sum(lines > 0, na.rm = TRUE))
  )
})

test_that("a line is only covered if all its expressions ran (#620)", {
  out <- to_lcov(shared_line_coverage(), tempfile())
  expect_equal(
    grep("^(DA|LF|LH):", out, value = TRUE),
    c("DA:2,1", "DA:3,0", "DA:6,0", "LF:3", "LH:1")
  )
})
