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

test_that("get_parse_data caches the files of each srcfile (#768)", {
  clean_parse_data()
  withr::defer(clean_parse_data())
  other <- srcfilecopy("other/R/a.R", c('#line 1 "other/R/a.R"', "a <- 1"))
  own <- srcfilecopy(
    "pkg/R/b.R",
    c('#line 1 "pkg/R/a.R"', "x <- 1", '#line 1 "pkg/R/b.R"', "y <- 2")
  )
  expect_equal(subset(get_parse_data(other), token == "SYMBOL")$text, "a")
  expect_equal(subset(get_parse_data(own), token == "SYMBOL")$text, "y")
  expect_setequal(
    ls(package_parse_data),
    c("other/R/a.R", "pkg/R/a.R", "pkg/R/b.R")
  )
})

test_that("get_parse_data parses a file again for another srcfile with its name", {
  clean_parse_data()
  withr::defer(clean_parse_data())
  first <- srcfilecopy("a.R", c('#line 1 "a.R"', "x <- 1"))
  second <- srcfilecopy("a.R", c('#line 1 "a.R"', "y <- 1"))
  expect_equal(subset(get_parse_data(first), token == "SYMBOL")$text, "x")
  expect_equal(subset(get_parse_data(second), token == "SYMBOL")$text, "y")
})

test_that("get_parse_data returns NULL for files that can't be parsed on their own", {
  clean_parse_data()
  withr::defer(clean_parse_data())
  expect_null(get_parse_data(srcfilecopy("a.R", c('#line 2 "a.R"', "x <- 1"))))
  expect_null(get_parse_data(srcfilecopy(
    "b.R",
    c('#line 1 "b.R"', "f <- function() {", '#line 3 "b.R"', "}")
  )))
  expect_null(get_parse_data(srcfilecopy(
    "c.R",
    c('#line 1 "c.R"', "x <- 1", '#line 12 "c.R"', "y <- 1")
  )))
})

test_that("get_parse_data returns NULL for srcfiles without a filename", {
  expect_null(get_parse_data(srcfilecopy("", "x <- 1")))
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

test_that("impute_child_srcrefs imputes the object of extractions and subsets", {
  p <- parse_srcrefs(c("a$b", "a@b", "x[[1]]", "x[, 1]"))
  cols <- function(i) {
    res <- impute_child_srcrefs(p$exprs[[i]], p$refs[[i]])
    lapply(res, function(ref) if (!is.null(ref)) as.integer(ref)[c(2, 4)])
  }
  expect_equal(cols(1), list(NULL, c(1L, 1L), NULL))
  expect_equal(cols(2), list(NULL, c(1L, 1L), NULL))
  expect_equal(cols(3), list(NULL, c(1L, 1L), c(4L, 4L)))
  expect_equal(cols(4), list(NULL, c(1L, 1L), NULL, c(5L, 5L)))
})

test_that("impute_child_srcrefs returns NULL for unsupported calls", {
  p <- parse_srcrefs("base::c")
  expect_null(impute_child_srcrefs(p$exprs[[1]], p$refs[[1]]))
})
