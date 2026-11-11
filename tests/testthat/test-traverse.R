test_that("full traversal is enabled from DESCRIPTION", {
  cov <- as.data.frame(package_coverage("TestFullTraversal"))

  expect_equal(
    cov$functions,
    c("fun_list$a", "fun_list$b", "api$helper", "api")
  )
  expect_equal(cov$first_line, c(3, 6, 12, 14))
  expect_equal(cov$value, c(1, 0, 1, 1))
})

test_that("the option overrides DESCRIPTION", {
  withr::local_options(covr.full_traversal = FALSE)
  cov <- as.data.frame(package_coverage("TestFullTraversal"))

  expect_equal(cov$functions, "api")
})

test_that("full traversal is off by default", {
  src <- "fns <- list(a = function() {\n  1\n})\n"
  cov <- as.data.frame(code_coverage(src, "fns$a()"))
  expect_equal(nrow(cov), 0)

  withr::local_options(covr.full_traversal = TRUE)
  cov <- as.data.frame(code_coverage(src, "fns$a()"))
  expect_equal(cov$functions, "fns$a")
  expect_equal(cov$value, 1)
})

test_that("full traversal skips functions from other packages", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "fns <- list(mean = mean, sd = stats::sd, f = function() {\n  1\n})\n"
  cov <- as.data.frame(code_coverage(src, "fns$f()"))

  expect_equal(cov$functions, "fns$f")
})

test_that("full traversal handles environments that reference themselves", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "e <- new.env()\ne$self <- e\ne$f <- function() {\n  1\n}\n"
  cov <- as.data.frame(code_coverage(src, "e$f()"))

  expect_equal(cov$functions, "e$f")
  expect_equal(cov$value, 1)
})

test_that("full traversal names methods after their own top level object", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "a <- new.env()\nb <- new.env()\na$super <- b\nb$f <- function() {\n  1\n}\n"
  cov <- as.data.frame(code_coverage(src, "b$f()"))

  expect_equal(cov$functions, "b$f")
})

test_that("full traversal does not dispatch on list classes", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "v <- package_version(\"1.2.3\")\nf <- function() {\n  1\n}\n"
  cov <- as.data.frame(code_coverage(src, "f()"))

  expect_equal(cov$functions, "f")
})

test_that("full traversal does not force promises", {
  withr::local_options(covr.full_traversal = TRUE, covr_test_value = "before")
  src <- "make <- function(x) function() x\napi <- make(getOption(\"covr_test_value\"))\n"
  test <- "options(covr_test_value = \"after\")\nstopifnot(identical(api(), \"after\"))\n"

  expect_no_error(code_coverage(src, test))
})

test_that("full traversal traces equal but separate closures", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "expr <- quote(function() {\n  1\n})\nfns <- list(a = eval(expr), b = eval(expr))\n"
  cov <- as.data.frame(code_coverage(src, "fns$b()"))

  expect_equal(cov$functions, "fns$a")
  expect_equal(cov$value, 1)
})

test_that("full traversal walks nested enclosing environments", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "api <- local({\n  helper <- function() {\n    1\n  }\n  local(function() helper())\n})\n"
  cov <- as.data.frame(code_coverage(src, "api()"))

  expect_equal(cov$functions, c("api$helper", "api"))
  expect_equal(cov$value, c(1, 1))
})

test_that("full traversal visits shared lists once", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "x <- NULL\nfor (i in seq_len(40)) x <- list(x, x)\nf <- function() {\n  1\n}\n"
  cov <- as.data.frame(code_coverage(src, "f()"))

  expect_equal(cov$functions, "f")
})

test_that("full traversal names functions without srcrefs", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "g <- function() {\n  1\n}\nf <- g\nattr(f, \"srcref\") <- NULL\nfns <- list(a = f)\n"
  cov <- as.data.frame(code_coverage(src, "fns$a()"))

  expect_equal(cov$functions, "g")
  expect_equal(cov$value, 1)
})

test_that("full traversal skips functions not created in the traced environment", {
  withr::local_options(covr.full_traversal = TRUE)
  src <- "f <- function() {\n  1\n}\nenvironment(f) <- baseenv()\nfns <- list(a = f, b = function() {\n  2\n})\n"
  cov <- as.data.frame(code_coverage(src, "fns$a()"))

  expect_equal(cov$functions, c("f", "fns$b"))
  expect_equal(cov$value, c(1, 0))
})

test_that("active bindings are not read when looking for functions", {
  src <- paste(
    "makeActiveBinding('ab', function() stop('boom'), environment())",
    "f <- function() {",
    "  1",
    "}",
    sep = "\n"
  )
  for (full in c(FALSE, TRUE)) {
    withr::local_options(covr.full_traversal = full)
    cov <- as.data.frame(code_coverage(src, "f()"))
    expect_equal(cov$functions, "f")
    expect_equal(cov$value, 1)
  }
})

test_that("active bindings in a package are not read", {
  dir <- withr::local_tempdir()
  file.copy("TestFullTraversal", dir, recursive = TRUE)
  pkg <- file.path(dir, "TestFullTraversal")
  # Active bindings can't be defined at the top level of an installed package,
  # as saving them for lazy loading evaluates them.
  cat(
    ".onLoad <- function(libname, pkgname) {\n",
    "  makeActiveBinding('ab', function() stop('boom'), topenv())\n",
    "}\n",
    file = file.path(pkg, "R", "TestFullTraversal.R"),
    append = TRUE
  )
  for (full in c(FALSE, TRUE)) {
    withr::local_options(covr.full_traversal = full)
    cov <- as.data.frame(package_coverage(pkg))
    expect_contains(cov$functions, "api")
  }
})
