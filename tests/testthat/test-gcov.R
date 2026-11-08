test_that("parse_gcov parses files properly", {
  local_mocked_bindings(
    # functions called within parse_gcov
    file.exists = function(path) TRUE,
    normalize_path = function(path) "simple.c",
    line_coverages = function(source_file, matches, values, ...) values
  )

  with_mocked_bindings(
    readLines = function(x) {
      "        -:    0:Source:simple.c"
    },
    expect_equal(parse_gcov("hi.c.gcov"), numeric())
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
    expect_equal(parse_gcov("hi.c.gcov"), 4)
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
        "    #####:    8:    pout[0] = 0;",
        "    =====:    9:    pout[0] = 1;"
      )
    },
    expect_equal(parse_gcov("hi.c.gcov"), c(4, 0, 0))
  )
})

test_that("parse_gcov counts partially executed lines (#604)", {
  local_mocked_bindings(
    file.exists = function(path) TRUE,
    normalize_path = function(path) "simple.c",
    line_coverages = function(source_file, matches, values, ...) {
      stats::setNames(values, matches$line)
    },
    readLines = function(x) {
      c(
        "        -:    0:Source:simple.c",
        "        3:    2:int f(int verbose) {",
        "       3*:    4:  if (verbose) printf(\"reached\");",
        "    #####:    5:  never();"
      )
    }
  )

  expect_equal(parse_gcov("hi.c.gcov"), c(`2` = 3, `4` = 3, `5` = 0))

  withr::local_options(covr.gcov_partial = "uncovered")
  expect_equal(parse_gcov("hi.c.gcov"), c(`2` = 3, `4` = 0, `5` = 0))
})

test_that("parse_gcov finds partially executed lines from block counts (#610)", {
  local_mocked_bindings(
    file.exists = function(path) TRUE,
    normalize_path = function(path) "simple.c",
    line_coverages = function(source_file, matches, values, ...) {
      stats::setNames(values, matches$line)
    }
  )
  withr::local_options(covr.gcov_partial = "uncovered")

  # llvm-cov does not mark partial lines with `*`
  local_mocked_bindings(
    readLines = function(x) {
      c(
        "        -:    0:Source:simple.c",
        "        3:    2:int f(int verbose) {",
        "        3:    4:  if (verbose) printf(\"reached\");",
        "        3:    4-block  0",
        "    $$$$$:    4-block  1",
        "    #####:    5:  never();",
        "    $$$$$:    5-block  0",
        "        3:    6:  return 0;",
        "        3:    6-block  0"
      )
    }
  )
  expect_equal(
    parse_gcov("hi.c.gcov", unexecuted_block = "$$$$$"),
    c(`2` = 3, `4` = 0, `5` = 0, `6` = 3)
  )

  # gcc >= 8 uses `$$$$$` for blocks only reached by exceptions
  local_mocked_bindings(
    readLines = function(x) {
      c(
        "        -:    0:Source:simple.cc",
        "       1*:    5:  if (x > 100) throw std::runtime_error(\"big\");",
        "        1:    5-block  0",
        "    %%%%%:    5-block  1",
        "        1:    8:  std::string s = \"abc\";",
        "        1:    8-block  0",
        "    $$$$$:    8-block  1"
      )
    }
  )
  expect_equal(parse_gcov("hi.c.gcov"), c(`5` = 0, `8` = 1))
})

test_that("parse_gcov counts the lines of template instantiations once (#609)", {
  local_mocked_bindings(
    file.exists = function(path) TRUE,
    normalize_path = function(path) "simple.cc",
    line_coverages = function(source_file, matches, values, ...) {
      stats::setNames(values, matches$line)
    },
    readLines = function(x) {
      c(
        "        -:    0:Source:simple.cc",
        "        4:    2:T twice(T x) {",
        "       1*:    3:  return x > 0 ? x * 2 : f(x);",
        "------------------",
        "_Z5twiceIdET_S0_:",
        "        2:    2:T twice(T x) {",
        "        2:    3:  return x > 0 ? x * 2 : f(x);",
        "        1:    3-block  0",
        "        1:    3-block  1",
        "------------------",
        "int twice<int>(int):",
        "        2:    2:T twice(T x) {",
        "    #####:    3:  return x > 0 ? x * 2 : f(x);",
        "    %%%%%:    3-block  0",
        "------------------",
        "        1:    5:int main() {"
      )
    }
  )

  expect_equal(parse_gcov("hi.cc.gcov"), c(`2` = 4, `3` = 1, `5` = 1))

  withr::local_options(covr.gcov_partial = "uncovered")
  expect_equal(parse_gcov("hi.cc.gcov"), c(`2` = 4, `3` = 0, `5` = 1))
})

test_that("parse_gcov_json parses gcov's JSON output (#609)", {
  pkg <- withr::local_tempdir()
  dir.create(file.path(pkg, "src"))
  writeLines(paste("line", 1:6), file.path(pkg, "src", "simple.cc"))
  header <- withr::local_tempfile(lines = paste("line", 1:3))

  gcov_line <- function(line_number, count, unexecuted_block = FALSE) {
    list(
      line_number = line_number,
      count = count,
      unexecuted_block = unexecuted_block
    )
  }
  json <- list(
    format_version = "1",
    current_working_directory = file.path(pkg, "src"),
    files = list(
      list(file = header, lines = list(gcov_line(2, 1))),
      list(
        file = "simple.cc",
        lines = list(
          # a template instantiated twice lists its lines once for each
          gcov_line(2, 2),
          gcov_line(3, 1),
          gcov_line(4, 0, TRUE),
          gcov_line(2, 2),
          gcov_line(3, 1, TRUE),
          gcov_line(4, 1),
          gcov_line(6, 0)
        )
      )
    )
  )
  file <- withr::local_tempfile(fileext = ".gcov.json.gz")
  con <- gzfile(file, "w")
  writeLines(jsonlite::toJSON(json, auto_unbox = TRUE), con)
  close(con)

  coverage <- function() {
    res <- parse_gcov_json(file, package_path = normalize_path(pkg))
    stats::setNames(
      vdapply(res, function(x) x$value),
      viapply(res, function(x) x$srcref[[1]])
    )
  }

  expect_equal(coverage(), c(`2` = 4, `3` = 2, `4` = 1, `6` = 0))

  withr::local_options(covr.gcov_partial = "uncovered")
  expect_equal(coverage(), c(`2` = 4, `3` = 0, `4` = 0, `6` = 0))
})

test_that("gcov_json_supported checks gcov's options (#609)", {
  json_supported <- function(help) {
    local_mocked_bindings(system_output = help)
    gcov_json_supported("gcov")
  }

  expect_true(json_supported(function(...) {
    c(
      "  -j, --json-format               Output JSON intermediate format",
      "                                    into .gcov.json.gz file"
    )
  }))
  expect_false(json_supported(function(...) {
    "  -i, --intermediate-format       Output .gcov file in intermediate text format"
  }))
  expect_false(json_supported(function(...) stop("failed")))
})

test_that("gcov_unexecuted_block depends on the gcov implementation (#610)", {
  unexecuted_block <- function(version) {
    local_mocked_bindings(system_output = function(...) version)
    gcov_unexecuted_block("gcov")
  }

  expect_equal(
    unexecuted_block("gcov (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    "%%%%%"
  )
  expect_equal(unexecuted_block("gcov.exe (GCC) 8.3.0"), "%%%%%")
  expect_equal(
    unexecuted_block("gcov (x86_64-posix-seh, Built by MinGW-W64) 4.9.3"),
    "$$$$$"
  )
  expect_equal(
    unexecuted_block(c("Apple LLVM version 15.0.0", "  Optimized build.")),
    "$$$$$"
  )
  expect_equal(unexecuted_block(character()), "%%%%%")
})

test_that("gcov_run only fails when gcov does (#537)", {
  gcov_result <- function(output, status = NULL) {
    local_mocked_bindings(
      system2 = function(...) structure(output, status = status)
    )
    gcov_run("gcov", "utils.gcno")
  }
  no_lines <- function(...) {
    c(
      ...,
      "./utils.gcda:cannot open data file, assuming not executed",
      "No executable lines"
    )
  }

  expect_equal(
    gcov_result(no_lines("./utils.gcno:no functions found")),
    no_lines("./utils.gcno:no functions found")
  )
  expect_snapshot(error = TRUE, {
    gcov_result(no_lines("./utils.gcno:cannot open notes file"), 1L)
    gcov_result(no_lines("./utils.gcno:not a gcov notes file"), 2L)
    gcov_result(
      no_lines(
        "./utils.gcno:version 'B33*', prefer 'B13*'",
        "./utils.gcno:no functions found"
      ),
      3L
    )
    gcov_result(
      no_lines("./utils.gcno:corrupted", "./utils.gcno:no functions found"),
      4L
    )
  })
})

test_that("clean_gcov correctly clears files", {
  dir <- file.path(tempfile(), "src")

  dir.create(dir, recursive = TRUE)
  file.create(file.path(
    dir,
    c("simple.c", "Makevars", "simple.c.gcov", "simple.gcda", "simple.gcno")
  ))
  expect_identical(
    list.files(dir),
    sort(c(
      "simple.c",
      "Makevars",
      "simple.c.gcov",
      "simple.gcda",
      "simple.gcno"
    ))
  )

  clean_gcov(dirname(dir))
  expect_identical(list.files(dir), sort(c("simple.c", "Makevars")))
})
