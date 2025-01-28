test_that("Summary gives 50% coverage and two lines with zero coverage", {
  cv <- package_coverage(test_path("TestSummary"))
  expect_equal(percent_coverage(cv), 50)
  expect_equal(nrow(zero_coverage(cv)), 2)
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
  expect_equal(res, 83.333333, tolerance = .01)
})
