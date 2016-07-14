context("corner-cases")

test_that("corner-cases are handled as expected", {
  cov <- file_coverage("corner-cases.R", "corner-cases-test.R")
  expect_equal(as.data.frame(cov), readRDS("corner-cases.Rds"))
})
