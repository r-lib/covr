test_that("corner-cases are handled as expected", {
  expect_warning(withr::with_output_sink(tempfile(), {
    cov <- file_coverage("corner-cases.R", "corner-cases-test.R")
  }))

  expect_equal(as.data.frame(cov), readRDS("corner-cases.Rds"))
})
