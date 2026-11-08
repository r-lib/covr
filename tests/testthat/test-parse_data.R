test_that("counts do not depend on keep.parse.data in other processes", {
  skip_on_cran()
  pkg <- local_keep_parse_data_package()
  code <- paste(
    "library(parsePkg); h(TRUE)",
    "system2(file.path(R.home('bin'), 'Rscript'), c('-e',",
    "shQuote('options(keep.parse.data = FALSE); library(parsePkg); h(TRUE)')))",
    sep = "\n"
  )

  cov <- package_coverage(pkg, type = "none", code = code, quiet = TRUE)
  res <- as.data.frame(cov)
  res <- res[res$filename == file.path("R", "b.R"), ]
  expect_equal(res$first_line, c(2, 3))
  expect_equal(res$value, c(2, 2))
})
