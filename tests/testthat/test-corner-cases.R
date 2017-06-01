context("corner-cases")

test_that("corner-cases are handled as expected", {
  expect_warning(withr::with_output_sink(tempfile(), {
    cov <- file_coverage("corner-cases.R", "corner-cases-test.R")
  }))

  cov <- as.data.frame(cov)
  cov <- cov[cov$filename == "corner-cases.R",]
  rownames(cov) <- NULL # get default row names after removing some files
  expect_equal(cov, readRDS("corner-cases.Rds"))
})
