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
