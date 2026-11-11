test_that("Compiled code coverage is reported including code in headers", {
  skip_on_cran()
  skip_if(is_win_r41())

  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))

  simple_cc <- cov[cov$filename == "src/simple.cc", ]
  expect_equal(simple_cc[simple_cc$first_line == "10", "value"], 4)

  expect_equal(simple_cc[simple_cc$first_line == "16", "value"], 3)

  expect_equal(simple_cc[simple_cc$first_line == "19", "value"], 0)

  expect_equal(simple_cc[simple_cc$first_line == "21", "value"], 1)

  expect_equal(simple_cc[simple_cc$first_line == "23", "value"], 4)

  # This header contains a C++ template, which requires you to run gcov for
  # each object file separately and merge the results together.
  simple_h <- cov[cov$filename == "src/simple-header.h", ]
  expect_equal(simple_h[simple_h$first_line == "12", "value"], 4)

  expect_equal(simple_h[simple_h$first_line == "18", "value"], 3)

  expect_equal(simple_h[simple_h$first_line == "21", "value"], 0)

  expect_equal(simple_h[simple_h$first_line == "23", "value"], 1)

  expect_equal(simple_h[simple_h$first_line == "25", "value"], 4)

  expect_in(
    unique(cov$filename),
    c(
      "R/TestCompiled.R",
      "src/simple-header.h",
      "src/simple.cc",
      "src/simple4.cc"
    )
  )
})

test_that("Can pass path to relative_path argument", {
  skip_on_cran()
  skip_if(is_win_r41())
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = "."))

  expect_in(
    unique(cov$filename),
    c(
      "TestCompiled/R/TestCompiled.R",
      "TestCompiled/src/simple-header.h",
      "TestCompiled/src/simple.cc",
      "TestCompiled/src/simple4.cc"
    )
  )
})

test_that("Rcpp interfaces header and .covrignore files are excluded (#531)", {
  skip_on_cran()
  skip_if(is_win_r41())
  pkg <- normalize_path("TestRcpp.Interfaces")
  files <- c("R/simple.R", "src/simple.cc", "inst/include/helper.h")
  withr::local_dir(tempdir())

  cov <- as.data.frame(package_coverage(pkg, relative_path = TRUE))
  expect_setequal(unique(cov$filename), files)

  cov <- as.data.frame(package_coverage(pkg, relative_path = FALSE))
  expect_setequal(unique(cov$filename), file.path(pkg, files))

  cov <- as.data.frame(package_coverage(pkg, relative_path = dirname(pkg)))
  expect_setequal(
    unique(cov$filename),
    file.path("TestRcpp.Interfaces", files)
  )
})

test_that("Source code subdirectories are found", {
  skip_on_cran()
  skip_if(is_win_r41())
  cov <- as.data.frame(package_coverage(
    "TestCompiledSubdir",
    relative_path = TRUE
  ))

  expect_equal(cov[cov$first_line == "9", "value"], 4)

  expect_equal(cov[cov$first_line == "15", "value"], 3)

  expect_equal(cov[cov$first_line == "18", "value"], 0)

  expect_equal(cov[cov$first_line == "20", "value"], 1)

  expect_equal(cov[cov$first_line == "22", "value"], 4)
})

test_that("Compiled code coverage is reported under non-standard char's", {
  skip_on_cran()
  skip_if(is_win_r41())
  cov <- as.data.frame(package_coverage(
    "Test+Char/TestCompiled",
    relative_path = TRUE
  ))

  expect_equal(cov[cov$first_line == "9", "value"], 4)

  expect_equal(cov[cov$first_line == "15", "value"], 3)

  expect_equal(cov[cov$first_line == "18", "value"], 0)

  expect_equal(cov[cov$first_line == "20", "value"], 1)

  expect_equal(cov[cov$first_line == "22", "value"], 4)
})

test_that("Partially executed compiled lines can count as uncovered (#610)", {
  skip_on_cran()
  skip_if(is_win_r41())

  cov <- as.data.frame(package_coverage("TestCompiledPartial"))
  expect_equal(cov[cov$first_line == "5", "value"], 1)

  withr::local_options(covr.gcov_partial = "uncovered")
  cov <- as.data.frame(package_coverage("TestCompiledPartial"))
  expect_equal(cov[cov$first_line == "5", "value"], 0)
  expect_equal(cov[cov$first_line == "6", "value"], 1)
})

test_that("Error thrown for missing gcov", {
  skip_on_cran()

  withr::local_options(covr.gcov = NA_character_)
  expect_snapshot(
    package_coverage("TestCompiled", relative_path = TRUE),
    error = TRUE
  )
})

test_that("covr.gcov = '' turns off compiled code coverage", {
  skip_on_cran()

  withr::local_options(covr.gcov = '')
  cov <- as.data.frame(package_coverage("TestCompiled", relative_path = TRUE))
  expect_equal(sum(startsWith(cov$filename, "src/")), 0)
  expect_gt(nrow(cov), 0)
})

test_that("Warning thrown for empty gcov output", {
  skip_on_cran()

  local_mocked_bindings(gcov_run = function(...) invisible())
  expect_snapshot(
    . <- package_coverage("TestCompiled", relative_path = TRUE),
    transform = function(x) gsub(getwd(), "<wd>", x)
  )
})

test_that("gcov's JSON and text output give the same coverage (#609)", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not(gcov_json_supported(resolve_gcov()))

  json <- as.data.frame(package_coverage("TestCompiled"))
  local_mocked_bindings(gcov_json_supported = function(...) FALSE)
  text <- as.data.frame(package_coverage("TestCompiled"))

  expect_equal(json, text)
})

test_that("tally_coverage includes compiled code", {
  skip_on_cran()
  skip_if(is_win_r41())

  cov <- package_coverage(test_path("TestCompiled"))
  tall <- tally_coverage(cov)

  expect_named(tall, c("filename", "functions", "line", "value"))

  expect_equal(
    unique(tall$filename),
    c(
      "R/TestCompiled.R",
      "src/simple-header.h",
      "src/simple.cc",
      "src/simple4.cc"
    )
  )
})

test_that("gcov's text output is used if its JSON output can't be used (#609)", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not(gcov_json_supported(resolve_gcov()))

  compiled <- function() {
    cov <- as.data.frame(package_coverage(test_path("TestCompiled")))
    cov <- cov[grepl("[.](c|cc|cpp|h)$", cov$filename), ]
    rownames(cov) <- NULL
    cov
  }
  local_mocked_bindings(gcov_json_supported = function(...) FALSE)
  text <- compiled()
  expect_gt(nrow(text), 0)

  # The JSON can't be parsed
  local_mocked_bindings(
    gcov_json_supported = function(...) TRUE,
    parse_gcov_json = function(...) stop("unexpected JSON")
  )
  expect_equal(compiled(), text)

  # gcov wrote no JSON output
  run <- gcov_run
  local_mocked_bindings(
    gcov_json_supported = function(...) TRUE,
    gcov_run = function(gcov_path, args, ...) {
      run(gcov_path, setdiff(args, "--json-format"), ...)
    }
  )
  expect_equal(compiled(), text)
})

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
  gcov_result <- function(output, status = 0L) {
    local_mocked_bindings(
      run_command = function(...) {
        list(status = status, stdout = output, stderr = character())
      }
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

  dir <- normalize_path(withr::local_tempdir())
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

test_that("find_gcov returns the path of gcov on the path", {
  skip_on_os("windows")
  dir <- withr::local_tempdir()
  gcov <- file.path(dir, "gcov")
  file.create(gcov)
  Sys.chmod(gcov, "755")
  withr::local_path(dir, action = "replace")

  # macOS's temp dir is a symlink, which `Sys.which()` resolves
  expect_equal(normalize_path(find_gcov()), normalize_path(gcov))
})

test_that("parse_gcov_json returns NULL for a missing file", {
  expect_null(parse_gcov_json(withr::local_tempfile()))
})

test_that("gcov_run reports the command and output when not quiet", {
  # shQuote() quotes differently on Windows
  skip_on_os("windows")
  local_mocked_bindings(
    run_command = function(...) {
      list(status = 0L, stdout = "line one", stderr = character())
    }
  )
  expect_snapshot(gcov_run("gcov", c("a b.gcno", "-a"), quiet = FALSE))
})

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
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) FALSE
  )

  res <- run_gcov(pkg, gcov_path = "gcov")
  expect_length(res, 1)
  expect_equal(list.files(file.path(pkg, "src")), c("f.c", "f.gcno"))
  expect_equal(list.files(pkg), "src")
})

test_that("run_gcov(clean = FALSE) moves gcov outputs to the covr directory", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) FALSE
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
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) FALSE
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
  expect_snapshot(cat(gsub(pkg, "<pkg>", msgs(FALSE), fixed = TRUE), sep = ""))
})

test_that("run_gcov reports errors in gcov's text output", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) FALSE,
    parse_gcov = function(...) stop("can't parse")
  )

  expect_snapshot(run_gcov(pkg, gcov_path = "gcov"), error = TRUE)
})

test_that("run_gcov says when it uses the text output instead of JSON", {
  pkg <- local_gcov_package()
  local_mocked_bindings(
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) TRUE
  )

  expect_message(
    res <- run_gcov(pkg, quiet = FALSE, gcov_path = "gcov"),
    "Falling back to gcov's text output"
  )
  expect_length(res, 1)
})

test_that("run_gcov only parses and cleans the reports gcov wrote", {
  pkg <- local_gcov_package()
  src <- file.path(pkg, "src")
  writeLines("int g() { return 2; }", file.path(src, "g.c"))
  write_gcov_report(file.path(src, "g.c.gcov"), "g.c")
  local_mocked_bindings(
    gcov_run = fake_gcov_run,
    gcov_unexecuted_block = function(...) "%%%%%",
    gcov_json_supported = function(...) FALSE
  )
  covered_files <- function(res) {
    basename(vcapply(res, function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    }))
  }

  res <- run_gcov(pkg, gcov_path = "gcov")
  expect_equal(unname(covered_files(res)), "f.c")
  expect_equal(list.files(src), c("f.c", "f.gcno", "g.c", "g.c.gcov"))

  res <- run_gcov(pkg, clean = FALSE, gcov_path = "gcov")
  expect_equal(unname(covered_files(res)), "f.c")
  expect_equal(list.files(src), c("f.c", "f.gcno", "g.c", "g.c.gcov"))
  expect_equal(
    basename(list.files(file.path(pkg, "covr"), recursive = TRUE)),
    "f.c.gcov"
  )
})

test_that("new_gcov_reports() finds the reports that are new or were rewritten", {
  before <- c("./a.gcov" = "10 1", "./b.gcov" = "20 2", "./c.gcov" = "30 3")
  after <- c("./a.gcov" = "10 1", "./b.gcov" = "21 5", "./d.gcov" = "40 4")
  expect_equal(new_gcov_reports(before, after), c("./b.gcov", "./d.gcov"))
  expect_equal(new_gcov_reports(character(), after), names(after))
  expect_equal(new_gcov_reports(before, character()), character())
})

test_that("gcov_reports() lists the sizes and times of matching reports", {
  withr::local_dir(withr::local_tempdir())
  dir.create("sub")
  writeLines("a", "x.gcov")
  writeLines("bb", "sub/y.gcov")
  writeLines("c", "z.gcda")

  reports <- gcov_reports("[.]gcov$")
  expect_named(reports, c("./sub/y.gcov", "./x.gcov"))
  expect_length(gcov_reports("[.]json$"), 0)
})

test_that("resolve_gcov() looks for gcov unless covr.gcov is set", {
  local_mocked_bindings(find_gcov = function() "/usr/bin/gcov")
  withr::local_options(covr.gcov = NULL)
  expect_equal(resolve_gcov(), "/usr/bin/gcov")

  withr::local_options(covr.gcov = "/opt/gcov-13")
  expect_equal(resolve_gcov(), "/opt/gcov-13")
  withr::local_options(covr.gcov = "")
  expect_equal(resolve_gcov(), "")
  withr::local_options(covr.gcov = NA_character_)
  expect_equal(resolve_gcov(), NA_character_)
})

test_that("resolve_gcov() finds gcov with the build tools on the PATH", {
  withr::local_options(covr.gcov = NULL)
  local_mocked_bindings(
    with_build_tools = function(code) {
      withr::local_path("/rtools/bin")
      code
    },
    find_gcov = function() Sys.getenv("PATH")
  )

  expect_match(resolve_gcov(), "/rtools/bin", fixed = TRUE)
})

test_that("in_package_path() compares whole path components", {
  dir <- normalize_path(withr::local_tempdir())
  files <- file.path(
    dir,
    c("pkg/src/a.c", "pkg2/src/a.c", "other/pkg/src/a.c", "pkg/missing.c")
  )
  for (file in files[1:3]) {
    dir.create(dirname(file), recursive = TRUE)
    file.create(file)
  }
  in_path <- function(roots) {
    unname(vlapply(files, in_package_path, package_path = roots))
  }

  expect_equal(in_path(file.path(dir, "pkg")), c(TRUE, FALSE, FALSE, FALSE))
  expect_equal(
    in_path(paste0(file.path(dir, "pkg"), "/")),
    c(TRUE, FALSE, FALSE, FALSE)
  )
  expect_equal(
    in_path(file.path(dir, "pkg/src/a.c")),
    c(TRUE, FALSE, FALSE, FALSE)
  )
  expect_equal(in_path(file.path(dir, "pkg", "sr")), rep(FALSE, 4))
})

test_that("in_package_path() accepts any of several roots, but not mid-path", {
  dir <- normalize_path(withr::local_tempdir())
  files <- file.path(dir, c("pkg/src/a.c", "extra/b.c", "extra2/c.c"))
  for (file in files) {
    dir.create(dirname(file), recursive = TRUE)
    file.create(file)
  }
  in_path <- function(roots) {
    unname(vlapply(files, in_package_path, package_path = roots))
  }

  # `/src` is a directory in the middle of the first path
  expect_equal(in_path(c(file.path(dir, "nope"), "/src")), rep(FALSE, 3))
  expect_equal(
    in_path(c(file.path(dir, "pkg"), file.path(dir, "extra"))),
    c(TRUE, TRUE, FALSE)
  )
})

test_that("in_package_path() treats the characters of roots literally", {
  dir <- normalize_path(withr::local_tempdir())
  files <- file.path(dir, c("a+b/x.c", "aab/x.c", "pkg (1)/x.c"))
  for (file in files) {
    dir.create(dirname(file), recursive = TRUE)
    file.create(file)
  }
  in_path <- function(roots) {
    unname(vlapply(files, in_package_path, package_path = roots))
  }

  expect_equal(in_path(file.path(dir, "a+b")), c(TRUE, FALSE, FALSE))
  expect_equal(in_path(file.path(dir, "pkg (1)")), c(FALSE, FALSE, TRUE))
})

test_that("in_package_path() without a root only needs the file to exist", {
  file <- withr::local_tempfile()
  file.create(file)

  expect_equal(in_package_path(file, ""), TRUE)
  expect_equal(in_package_path(tempfile(), ""), FALSE)
})

test_that("parse_gcov() only accepts sources in the package's own directory", {
  dir <- normalize_path(withr::local_tempdir())
  pkg <- file.path(dir, "pkg")
  sibling <- file.path(dir, "pkg2")
  dir.create(pkg)
  dir.create(sibling)
  writeLines("int f() { return 1; }", file.path(sibling, "f.c"))
  gcov <- file.path(dir, "f.c.gcov")
  write_gcov_report(gcov, file.path(sibling, "f.c"))

  expect_null(parse_gcov(gcov, package_path = pkg))
  expect_length(parse_gcov(gcov, package_path = c(pkg, sibling)), 1)
})
