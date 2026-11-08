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

test_that("parse_gcov ignores missing files and sources outside the package", {
  expect_null(parse_gcov(tempfile(fileext = ".c.gcov")))

  dir <- withr::local_tempdir()
  other <- file.path(dir, "other")
  pkg <- file.path(dir, "pkg")
  dir.create(other)
  dir.create(pkg)
  writeLines("int f() { return 1; }", file.path(other, "f.c"))
  gcov <- file.path(dir, "f.c.gcov")
  writeLines(
    c(
      paste0("        -:    0:Source:", file.path(other, "f.c")),
      "        1:    1:int f() { return 1; }"
    ),
    gcov
  )

  expect_null(parse_gcov(gcov, package_path = pkg))
  expect_length(parse_gcov(gcov, package_path = other), 1)
})

test_that("parse_gcov returns NULL when no lines are counted", {
  dir <- withr::local_tempdir()
  writeLines("#define X 1", file.path(dir, "f.c"))
  gcov <- file.path(dir, "f.c.gcov")
  writeLines(
    c(
      paste0("        -:    0:Source:", file.path(dir, "f.c")),
      "        -:    1:#define X 1"
    ),
    gcov
  )

  expect_null(parse_gcov(gcov, package_path = dir))
})

test_that("parse_gcov errors on coverage values it cannot parse", {
  local_mocked_bindings(
    file.exists = function(path) TRUE,
    normalize_path = function(path) "simple.c",
    readLines = function(x) {
      c("        -:    0:Source:simple.c", "     ###*#:    1:x;")
    }
  )
  expect_snapshot(suppressWarnings(parse_gcov("hi.c.gcov")), error = TRUE)
})

test_that("find_gcov returns NA when gcov is not on the path", {
  withr::local_path(character(), action = "replace")
  expect_equal(find_gcov(), NA_character_)
})

test_that("gcov_run reports the command and output when not quiet", {
  local_mocked_bindings(system2 = function(...) "line one")
  expect_snapshot(gcov_run("gcov", c("a b.gcno", "-a"), quiet = FALSE))
})

local_gcov_package <- function(env = parent.frame()) {
  pkg <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(pkg, "src"))
  writeLines("int f() { return 1; }", file.path(pkg, "src", "f.c"))
  file.create(file.path(pkg, "src", "f.gcno"))
  writeLines(
    c(
      "        -:    0:Source:f.c",
      "        1:    1:int f() { return 1; }"
    ),
    file.path(pkg, "src", "f.c.gcov")
  )
  normalizePath(pkg)
}

test_that("run_gcov returns without error when gcov is unavailable and unused", {
  pkg <- withr::local_tempdir()
  expect_null(run_gcov(pkg, gcov_path = NA_character_))

  dir.create(file.path(pkg, "src"))
  expect_null(run_gcov(pkg, gcov_path = NA_character_))

  file.create(file.path(pkg, "src", "f.gcno"))
  expect_snapshot(run_gcov(pkg, gcov_path = NA_character_), error = TRUE)
})

test_that("run_gcov cleans gcov outputs by default", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = function(...) NULL,
    gcov_unexecuted_block = function(...) "%%%%%"
  )

  res <- run_gcov(pkg, gcov_path = "gcov")
  expect_length(res, 1)
  expect_equal(list.files(file.path(pkg, "src")), c("f.c", "f.gcno"))
  expect_equal(list.files(pkg), "src")
})

test_that("run_gcov(clean = FALSE) moves gcov outputs to the covr directory", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = function(...) NULL,
    gcov_unexecuted_block = function(...) "%%%%%"
  )

  res <- run_gcov(pkg, clean = FALSE, gcov_path = "gcov")
  expect_length(res, 1)
  expect_equal(list.files(file.path(pkg, "src")), c("f.c", "f.gcno"))
  expect_equal(
    basename(list.files(file.path(pkg, "covr"), recursive = TRUE)),
    "f.c.gcov"
  )
})

test_that("run_gcov reports progress when not quiet", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = function(...) NULL,
    gcov_unexecuted_block = function(...) "%%%%%"
  )

  msgs <- function(clean) {
    out <- character()
    withCallingHandlers(
      run_gcov(pkg, quiet = FALSE, clean = clean, gcov_path = "gcov"),
      message = function(m) {
        out <<- c(out, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    )
    out
  }

  expect_snapshot(cat(msgs(TRUE), sep = ""))
  writeLines(
    c("        -:    0:Source:f.c", "        1:    1:int f() { return 1; }"),
    file.path(pkg, "src", "f.c.gcov")
  )
  expect_snapshot(cat(gsub(pkg, "<pkg>", msgs(FALSE), fixed = TRUE), sep = ""))
})
