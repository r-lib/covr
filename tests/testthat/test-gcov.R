test_that("parse_gcov parses files properly", {
  local_mocked_bindings(
    # Only called within parse_gcov
    file.exists = function(path) TRUE,
    # Only called within normalize_path
    normalize_path = function(path) "simple.c",
    # Only called within parse_gcov
    line_coverages = function(source_file, matches, values, ...) values
  )

  with_mocked_bindings(
    expect_equal(parse_gcov("hi.c.gcov"), numeric()),
    readLines = function(x) {
      "        -:    0:Source:simple.c"
    }
  )

  with_mocked_bindings(
    readLines = function(x) {
      c(
        "        -:    0:Source:simple.c",
        "        -:    1:#define USE_RINTERNALS"
      )
    },
    expect_equal(parse_gcov("hi.c.gcov"), numeric())
  )

  with_mocked_bindings(
    readLines = function(x) {
      c(
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
      )
    },
    code = expect_equal(parse_gcov("hi.c.gcov"), 4)
  )
  with_mocked_bindings(
    readLines = function(x) {
      c(
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
      )
    },
    code = expect_equal(parse_gcov("hi.c.gcov"), c(4, 0))
  )
})

test_that("clean_gcov correctly clears files", {

  dir <- file.path(tempfile(), "src")

  dir.create(dir, recursive = TRUE)
  file.create(file.path(dir, c("simple.c", "Makevars", "simple.c.gcov", "simple.gcda", "simple.gcno")))
  expect_identical(list.files(dir), sort(c("simple.c", "Makevars", "simple.c.gcov", "simple.gcda", "simple.gcno")))

  clean_gcov(dirname(dir))
  expect_identical(list.files(dir), sort(c("simple.c", "Makevars")))
})
