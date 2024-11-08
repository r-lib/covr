loaded_mods <- loadNamespace("box")$loaded_mods
rm(list = ls(loaded_mods), envir = loaded_mods)

test_that("R6 box module coverage is reported", {
  # Similar to test-R6.R, there is some sort of bug that causes this test
  # to fail during R CMD check in R-devel, not sure why, and can't reproduce
  # it interactively
  skip_if(is_r_devel())
  withr::with_dir("Testbox_R6", {
    cov <- as.data.frame(file_coverage(
        source_files = "app/app.R",
        test_files = list.files("tests/testthat", full.names = TRUE)))

    expect_equal(cov$value, c(1, 1))
    expect_equal(cov$first_line, c(5, 8))
    expect_equal(cov$last_line, c(5, 8))
    expect_true("show" %in% cov$functions)
  })
})
