test_that("counts do not depend on keep.parse.data in other processes", {
  skip_on_cran()
  # The child process's counts are missing on Windows CI (not yet diagnosed)
  skip_on_os("windows")
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

test_that("impute_srcref returns NULL for calls that are not conditionals or loops", {
  p <- parse_srcrefs("f(x)")
  expect_null(impute_srcref(p$exprs[[1]], p$refs[[1]]))
})

test_that("imputing srcrefs without a srcref or without matching parse data returns NULL", {
  expect_null(impute_child_srcrefs(quote(f(x)), NULL))
  expect_null(impute_body_srcref(NULL))
  expect_null(impute_formal_srcrefs(NULL))

  p <- parse_srcrefs("f(x)")
  ref <- p$refs[[1]]
  ref[[2L]] <- 50L
  expect_null(parse_children(ref))
})

test_that("impute_child_srcrefs imputes unary operators and calls without arguments", {
  p <- parse_srcrefs(c("f()", "-x"))
  expect_length(impute_child_srcrefs(p$exprs[[1]], p$refs[[1]]), 1L)

  res <- impute_child_srcrefs(p$exprs[[2]], p$refs[[2]])
  expect_length(res, 2L)
  expect_null(res[[1]])
  expect_equal(as.integer(res[[2]])[c(2, 4)], c(2L, 2L))
})

test_that("impute_child_srcrefs returns NULL for unsupported calls or mismatched parse data", {
  p <- parse_srcrefs(c("a$b", "x[[1]]"))
  expect_null(impute_child_srcrefs(p$exprs[[1]], p$refs[[1]]))
  expect_null(impute_child_srcrefs(p$exprs[[2]], p$refs[[2]]))
})
