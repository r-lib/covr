context("gcov")
test_that("gcov calls system2 and parse_gcov with the proper arguments", {
  # functions for testing
  get_args <- function(x) {
    eval(parse(text = attr(x, "condition")$message))
  }
  return_args <- function(...) {
    get_args(try(..., silent = TRUE))
  }
  with_mock(
    `base::system2` = function(...) {
      stop(capture.output(dput(list(...))))
    },
    `base::setwd` = function(...) invisible(),
    `base::file.exists` = function(..) TRUE,

    system2_args <- return_args(run_gcov("src/test.c")),

    expect_equal(system2_args[[1]], "gcov"),
    expect_equal(system2_args[[2]], "test.c"),

    expect_equal(names(system2_args)[3], "stdout"),
    expect_equal(system2_args[[3]], NULL)
  )

  with_mock(
    `base::system2` = function(...) invisible(),
    `base::setwd` = function(...) invisible(),
    `base::file.exists` = function(..) TRUE,
    `covr:::parse_gcov` = function(...) {
      stop(capture.output(dput(list(...))))
    },

    gcov_args <- return_args(run_gcov("src/test.c")),

    expect_equal(gcov_args[[1]], "src/test.c.gcov")
  )
})

test_that("parse_gcov parses files properly", {
  with_mock(
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c"
    ),
    expect_equal(parse_gcov("hi.c.gcov"), NULL)
  )

  with_mock(
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c",
"        -:    1:#define USE_RINTERNALS"
    ),
    expect_equal(parse_gcov("hi.c.gcov"), NULL)
  )

  with_mock(
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c",
"        -:    0:Graph:simple.gcno",
"        -:    0:Data:simple.gcda",
"        -:    0:Runs:1",
"        -:    0:Programs:1",
"        -:    1:#define USE_RINTERNALS",
"        -:    2:#include <R.h>",
"        -:    3:#include <Rdefines.h>",
"        -:    4:#include <R_ext/Error.h>",
"        -:    5:",
"        4:    6:SEXP simple_(SEXP x) {"
    ),
    expect_equal(parse_gcov("hi.c.gcov"),
      structure(c(`hi.c:6:NA:6:NA:NA:NA:NA:NA` = 4), class = "coverage"))
  )
  with_mock(
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c",
"        -:    0:Graph:simple.gcno",
"        -:    0:Data:simple.gcda",
"        -:    0:Runs:1",
"        -:    0:Programs:1",
"        -:    1:#define USE_RINTERNALS",
"        -:    2:#include <R.h>",
"        -:    3:#include <Rdefines.h>",
"        -:    4:#include <R_ext/Error.h>",
"        -:    5:",
"        4:    6:SEXP simple_(SEXP x) {",
"        -:    7:  }",
"    #####:    8:    pout[0] = 0;"
    ),
    expect_equal(parse_gcov("hi.c.gcov"),
      structure(
        c(`hi.c:6:NA:6:NA:NA:NA:NA:NA` = 4,
          `hi.c:8:NA:8:NA:NA:NA:NA:NA` = 0
          ), class = "coverage"))
  )
})
