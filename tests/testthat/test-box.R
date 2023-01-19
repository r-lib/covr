context("box")

test_that("box module coverage is reported", {
  withr::with_dir("tests/testthat/Testbox", {
    cov <- as.data.frame(file_coverage(
        source_files = "app/app.R",
        test_files = list.files("tests/testthat", full.name = TRUE)))

    expect_true("a" %in% cov$functions)
  })

})
