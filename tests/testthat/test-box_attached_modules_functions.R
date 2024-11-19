loaded_mods <- loadNamespace("box")$loaded_mods
rm(list = ls(loaded_mods), envir = loaded_mods)

test_that("box attached module coverage is reported", {
  withr::with_dir("Testbox_attached_modules_functions", {
    cov <- as.data.frame(file_coverage(
      source_files = "app/app.R",
      test_files = list.files("tests/testthat", full.names = TRUE)))

    expect_equal(cov$value, c(20, 8, 12, 3, 0))
    expect_equal(cov$first_line, c(5, 6, 8, 14, 18))
    expect_equal(cov$last_line, c(5, 6, 8, 14, 18))
    expect_true("a" %in% cov$functions)
    expect_true("private_function" %in% cov$functions)
  })

})
