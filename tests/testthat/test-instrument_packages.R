test_that("trace_coverage() reads the coverage of any processes that load instrumented packages", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  instrumented <- local_instrumented_packages(
    c("TestNestedInner", "TestNestedOuter"),
    pkgs$lib,
    traces,
    cores = 2
  )
  expect_equal(instrumented, c(TestNestedInner = TRUE, TestNestedOuter = TRUE))

  run_with_library(pkgs$lib, "TestNestedInner::inner_fun(1)")
  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")

  # Both files have an expression at the same position
  cov <- trace_coverage(traces)
  df <- tally_coverage(cov)
  expect_equal(
    df$filename,
    rep(c("TestNestedInner/R/utils.R", "TestNestedOuter/R/utils.R"), each = 2)
  )
  expect_equal(df$value, c(1, 1, 2, 2))

  # A Cobertura package for each package
  file <- withr::local_tempfile(fileext = ".xml")
  cobertura(cov, file)
  xml <- xml2::read_xml(file)
  expect_equal(
    xml2::xml_attr(xml2::xml_find_all(xml, "//package"), "name"),
    c("TestNestedInner", "TestNestedOuter")
  )

  # Functions are named by their package
  expect_message(
    print(cov, group = "functions"),
    "TestNestedOuter::outer_fun"
  )
})

test_that("trace_coverage() includes the instrumented packages that no process loaded", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local_instrumented_packages(
    c("TestNestedInner", "TestNestedOuter"),
    pkgs$lib,
    traces
  )

  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")

  df <- tally_coverage(trace_coverage(traces))
  expect_equal(
    df$filename,
    rep(c("TestNestedInner/R/utils.R", "TestNestedOuter/R/utils.R"), each = 2)
  )
  expect_equal(df$value, c(0, 0, 1, 1))
})

test_that("packages instrumented without trace_dir only save their counts in COVR_TRACE_DIR", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local_instrumented_packages(
    c("TestNestedInner", "TestNestedOuter"),
    pkgs$lib,
    trace_dir = NULL
  )

  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")
  run_with_library(
    pkgs$lib,
    "TestNestedOuter::outer_fun(1)",
    env = c(COVR_TRACE_DIR = traces)
  )

  expect_length(list.files(pkgs$lib, pattern = "^covr_"), 0)
  df <- tally_coverage(trace_coverage(traces, lib = pkgs$lib))
  expect_equal(df$value, c(0, 0, 1, 1))
})

test_that("trace_coverage() reads several trace directories", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  shards <- c(withr::local_tempdir(), withr::local_tempdir())
  local_instrumented_packages("TestNestedOuter", pkgs$lib, trace_dir = NULL)

  for (shard in shards) {
    run_with_library(
      pkgs$lib,
      "TestNestedOuter::outer_fun(1)",
      env = c(COVR_TRACE_DIR = shard)
    )
  }

  expect_equal(tally_coverage(trace_coverage(shards))$value, c(2, 2))
})

test_that("trace_coverage() warns and returns no coverage without any traces", {
  traces <- withr::local_tempdir()
  withr::local_dir(traces)
  expect_snapshot(cov <- trace_coverage("."))
  expect_s3_class(cov, "coverage")
  expect_length(cov, 0)
  expect_equal(lcov(cov, withr::local_tempfile()), character())
})

test_that("instrumented packages save their counts in COVR_TRACE_DIR if it is set", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  other <- withr::local_tempdir()
  local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)

  run_with_library(
    pkgs$lib,
    "TestNestedOuter::outer_fun(1)",
    env = c(COVR_TRACE_DIR = other)
  )

  expect_equal(tally_coverage(trace_coverage(other))$value, c(1, 1))
  expect_equal(tally_coverage(trace_coverage(traces))$value, c(0, 0))
})

test_that("trace_coverage() reads traces after the packages are restored", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local({
    local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)
    run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")
  })
  unlink(pkgs$lib, recursive = TRUE)

  expect_equal(tally_coverage(trace_coverage(traces))$value, c(1, 1))
})

test_that("instrumented packages save their counts in trace_dir if COVR_TRACE_DIR is empty", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)

  run_with_library(
    pkgs$lib,
    "TestNestedOuter::outer_fun(1)",
    env = c(COVR_TRACE_DIR = "")
  )

  expect_equal(tally_coverage(trace_coverage(traces))$value, c(1, 1))
})

test_that("trace_coverage(paths =) keeps the lines of each file of a package", {
  skip_on_cran()
  local_install_defaults()
  root <- withr::local_tempdir()
  pkg <- file.path(root, "build", "MultiPkg")
  moved <- file.path(root, "moved", "MultiPkg")
  lib <- file.path(root, "lib")
  dir.create(file.path(pkg, "R"), recursive = TRUE)
  dir.create(lib)
  writeLines(
    c("Package: MultiPkg", "Version: 0.1.0", "Title: T", "Description: T."),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("export(f_a, f_b)", file.path(pkg, "NAMESPACE"))
  writeLines(
    c("f_a <- function(x) {", "  x + 1", "}"),
    file.path(pkg, "R", "a.R")
  )
  writeLines(
    c(
      "f_b <- function(x) {",
      "  x * 2",
      "  if (FALSE) {",
      "    stop('never') # nocov",
      "  }",
      "}"
    ),
    file.path(pkg, "R", "b.R")
  )
  withr::with_envvar(c(R_ENVIRON = NA, R_PROFILE = NA), {
    system2(
      file.path(R.home("bin"), "R"),
      c(
        "CMD",
        "INSTALL",
        "--with-keep.source",
        "-l",
        shQuote(lib),
        shQuote(pkg)
      ),
      stdout = FALSE,
      stderr = FALSE
    )
  })
  traces <- withr::local_tempdir()
  local_instrumented_packages("MultiPkg", lib, traces)
  run_with_library(lib, "MultiPkg::f_a(1); MultiPkg::f_b(2)")

  as_installed <- tally_coverage(trace_coverage(traces))
  moved_cov <- trace_coverage(traces, paths = c(MultiPkg = moved))

  expect_equal(tally_coverage(moved_cov), as_installed)
  expect_equal(
    traced_files(moved_cov)[["R/b.R"]]$file_lines,
    readLines(file.path(pkg, "R", "b.R"))
  )
})

test_that("file_packages() puts each file in the deepest package that has it", {
  x <- structure(
    list(),
    package = list(
      package = c("parent", "child"),
      path = c("/repo", "/repo/child")
    ),
    root = "/repo",
    class = "coverage"
  )
  expect_equal(
    file_packages(x, c("R/a.R", "child/R/b.R")),
    list(parent = "R/a.R", child = "child/R/b.R")
  )
  attr(x, "root") <- NULL
  expect_equal(
    file_packages(x, c("/repo/R/a.R", "/repo/child/R/b.R", "/other/c.R")),
    list(parent = "/repo/R/a.R", child = "/repo/child/R/b.R", "/other/c.R")
  )
})

test_that("instrumenting a package again replaces its baseline trace", {
  dir <- withr::local_tempdir()
  old <- withr::local_tempfile(fileext = ".rds")
  new <- withr::local_tempfile(fileext = ".rds")
  saveRDS(list(a = 1), old)
  saveRDS(list(b = 2), new)

  save_baseline_trace(old, dir, "pkg")
  save_baseline_trace(new, dir, "pkg")

  baselines <- list.files(dir, pattern = "^covr_trace_", full.names = TRUE)
  expect_length(baselines, 1)
  expect_equal(
    readRDS(baselines)$counters_file,
    paste0("covr_counters_", unname(tools::md5sum(new)), ".rds")
  )
})

test_that("absolute_path() expands the home directory", {
  expect_equal(absolute_path("~/x"), normalize_path(path.expand("~/x")))
})

test_that("keep_counters_file() keeps the counters of a loaded package", {
  local_clean_traces()
  file <- withr::local_tempfile(fileext = ".rds")
  saveRDS(list(), file)
  entry <- scope_entry("pkg")
  entry$counters_file <- file

  keep_counters_file("pkg", file)
  unlink(file)

  expect_true(file.exists(scope_entry("pkg")$counters_file))
})

test_that("trace_coverage() gives the file names in the source directories in `paths`", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)
  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")
  installed_from <- file.path(pkgs$src, "TestNestedOuter")
  lines <- readLines(file.path(installed_from, "R", "utils.R"))

  for (moved in c(withr::local_tempdir(), file.path(installed_from, "copy"))) {
    cov <- trace_coverage(
      traces,
      paths = c(TestNestedOuter = moved),
      relative_path = FALSE
    )
    file <- file.path(normalize_path(moved), "R", "utils.R")
    expect_equal(unique(tally_coverage(cov)$filename), file)
    # The lines of the file are found by its new name
    expect_equal(traced_files(cov)[[file]]$file_lines, lines)
  }

  # A relative path that doesn't exist is relative to the working directory
  withr::with_dir(pkgs$src, {
    cov <- trace_coverage(
      traces,
      paths = c(TestNestedOuter = "missing/pkg"),
      relative_path = FALSE
    )
    expect_equal(
      unique(tally_coverage(cov)$filename),
      file.path(normalize_path(getwd()), "missing", "pkg", "R", "utils.R")
    )
  })

  # A function that maps each file, e.g. of a build that flattened them
  root <- normalize_path(withr::local_tempdir())
  cov <- trace_coverage(
    traces,
    paths = function(files, package) {
      file.path(root, package, "helpers", basename(files))
    },
    relative_path = root
  )
  expect_equal(
    unique(tally_coverage(cov)$filename),
    "TestNestedOuter/helpers/utils.R"
  )
  expect_equal(
    traced_files(cov)[["TestNestedOuter/helpers/utils.R"]]$file_lines,
    lines
  )
})

test_that("remove_covr_hooks() removes only the onLoad hooks of covr", {
  lib <- withr::local_tempdir()
  dir.create(file.path(lib, "covrHooksTest", "R"), recursive = TRUE)
  load_script <- file.path(lib, "covrHooksTest", "R", "covrHooksTest")
  writeLines(c("local({", "})"), load_script)
  add_hooks("covrHooksTest", lib)
  event <- packageEvent("covrHooksTest", "onLoad")
  withr::defer(setHook(event, NULL, "replace"))
  other <- function(...) covr::in_covr()
  setHook(event, other)
  pkg <- "covrHooksTest"
  for (line in grep("^setHook", readLines(load_script), value = TRUE)) {
    eval(parse(text = line))
  }
  expect_length(getHook(event), 6)

  remove_covr_hooks("covrHooksTest")

  expect_identical(getHook(event), list(other))
})

test_that("scope_compiled() prefixes the keys of the files of the package", {
  root <- normalize_path(withr::local_tempdir())
  trace <- function(file) {
    list(srcref = srcref(srcfilecopy(file, ""), c(1, 1, 1, 1)))
  }
  x <- list(
    "a.c:1:1:1:1" = trace(file.path(root, "pkg", "src", "a.c")),
    "b.c:1:1:1:1" = trace(file.path(root, "other", "b.c"))
  )
  expect_named(
    scope_compiled(x, list(package = "pkg", path = file.path(root, "pkg"))),
    c("pkg/a.c:1:1:1:1", "b.c:1:1:1:1")
  )
})

test_that("uninstrument_packages() restores the packages", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  r_dir <- file.path(pkgs$lib, "TestNestedOuter", "R")
  files <- tools::md5sum(list.files(r_dir, full.names = TRUE))

  local({
    local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)
    expect_false(identical(
      tools::md5sum(list.files(r_dir, full.names = TRUE)),
      files
    ))
  })

  expect_equal(tools::md5sum(list.files(r_dir, full.names = TRUE)), files)
  before <- list.files(traces)
  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")
  expect_equal(list.files(traces), before)
})

test_that("instrument_packages() errors for packages that are not installed or already instrumented", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()

  withr::with_dir(dirname(pkgs$lib), {
    expect_snapshot(
      instrument_packages("notapackage", "lib", traces),
      error = TRUE
    )
  })
  expect_snapshot(
    instrument_packages(c("TestNestedOuter", "TestNestedOuter"), pkgs$lib),
    error = TRUE
  )

  local_instrumented_packages("TestNestedOuter", pkgs$lib, traces)
  expect_snapshot(
    instrument_packages(c("TestNestedInner", "TestNestedOuter"), pkgs$lib),
    error = TRUE
  )
  # The package that wasn't instrumented is left as it was
  expect_false(file.exists(loader_original(pkgs$lib, "TestNestedInner")))
})

test_that("common_path() is the deepest directory that contains all paths", {
  expect_equal(common_path("/a/b"), "/a/b")
  expect_equal(common_path(c("/a/b/c", "/a/b/d")), "/a/b")
  expect_equal(common_path(c("/a/bc", "/a/b")), "/a")
  expect_equal(common_path(c("/a/b", "/a/b/c")), "/a/b")
  expect_equal(common_path(c("/a", "/b")), "/")
  expect_equal(common_path(c("C:/a/b", "C:/a/c")), "C:/a")
  expect_equal(common_path(c("C:/a", "C:/b")), "C:/")
  expect_null(common_path(c("C:/a", "D:/b")))
  expect_null(common_path(c("//serverA/share/a", "//serverB/share/b")))
  expect_equal(
    common_path(c("//server/share/a", "//server/share/b")),
    "//server/share"
  )
})

test_that("sort_by_dependencies() puts packages after those they need", {
  pkgs <- list(
    list(package = "c", imports = "b (>= 1.0),\n    stats"),
    list(package = "a"),
    list(package = "b", depends = "R (>= 4.1), a", linkingto = "cpp11")
  )
  expect_equal(
    vcapply(sort_by_dependencies(pkgs), `[[`, "package"),
    c("a", "b", "c")
  )
})

test_that("share_rust_profiles() leaves out packages built with another LLVM", {
  rust <- list(
    a = list(llvm_version = "18", profiles = "a", env = c(X = "a")),
    b = list(llvm_version = "19", profiles = "b", env = c(X = "b")),
    c = list(llvm_version = "18", profiles = "c", env = c(X = "c"))
  )
  expect_snapshot(shared <- share_rust_profiles(rust))
  expect_named(shared, c("a", "c"))
  expect_equal(shared$c$profiles, "a")
  expect_equal(rust_env(shared), c(X = "a"))
})
