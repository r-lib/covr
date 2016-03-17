context("gcov")
test_that("parse_gcov parses files properly", {
  with_mock(
    `base::file.exists` = function(...) TRUE,
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c"
    ),
    `base::normalizePath` = function(...) "simple.c",
    expect_equal(parse_gcov("hi.c.gcov"), NULL)
  )

  with_mock(
    `base::file.exists` = function(...) TRUE,
    `base::readLines` = function(...) c(
"        -:    0:Source:simple.c",
"        -:    1:#define USE_RINTERNALS"
    ),
    `base::normalizePath` = function(...) "simple.c",
    expect_equal(parse_gcov("hi.c.gcov"), NULL)
  )

  with_mock(
    `base::file.exists` = function(...) TRUE,
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
    `base::normalizePath` = function(...) "simple.c",
    expect_equal(unname(value(parse_gcov("hi.c.gcov"))), 4)
  )
  with_mock(
    `base::file.exists` = function(...) TRUE,
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
"    #####:    8:    pout[0] = 0;" # nolint
    ),
    `base::normalizePath` = function(...) "simple.c",
    expect_equal(value(unname(parse_gcov("hi.c.gcov"))), c(4, 0))
  )
})

test_that("clean_gcov correctly clears files", {
  with_mock(
    `base::list.files` = function(...) c("simple.c.gcov", "simple.gcda", "simple.gcno"),
    `base::unlink` = function(...) list(...),
    files <- clean_gcov("TestGcov")[[1]],
    expect_match(files[1], "simple.c.gcov"),
    expect_match(files[2], "simple.gcda"),
    expect_match(files[3], "simple.gcno")
  )
})
