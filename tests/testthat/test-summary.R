context("summary_functions")

test_that("Summary gives 50% coverage", {
  expect_equal(percent_coverage(package_coverage("TestSummary")), 50)
})

zero_Summary <- zero_coverage(package_coverage("TestSummary"))

test_that("Summary gives 1 lines with 0 coverage", {
  expect_equal(nrow(zero_Summary), 1)
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
