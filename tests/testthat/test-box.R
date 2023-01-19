context("box")

test_that("box module coverage is reported", {
  withr::with_dir("./Testbox", {
    cov <- as.data.frame(file_coverage(
        source_files = "app/app.R",
        test_files = list.files("tests/testthat", full.name = TRUE)))

    expect_equal(cov$value, c(5, 2, 3))
    expect_equal(cov$first_line, c(5, 6, 8))
    expect_equal(cov$last_line, c(5, 6, 8))
    expect_true("a" %in% cov$functions)
  })

})
