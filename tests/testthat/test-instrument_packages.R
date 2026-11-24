test_that("trace_coverage() reads the coverage of any processes that load instrumented packages", {
  skip_on_cran()
  local_install_defaults()
  pkgs <- local_nested_library()
  traces <- withr::local_tempdir()
  local_instrumented_packages(
    c("TestNestedInner", "TestNestedOuter"),
    pkgs$lib,
    traces
  )

  run_with_library(pkgs$lib, "TestNestedInner::inner_fun(1)")
  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")

  # Both files have an expression at the same position
  df <- tally_coverage(trace_coverage(traces))
  expect_equal(
    df$filename,
    rep(c("TestNestedInner/R/utils.R", "TestNestedOuter/R/utils.R"), each = 2)
  )
  expect_equal(df$value, c(1, 1, 2, 2))
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
  withr::local_dir(traces)
  expect_snapshot(trace_coverage("."), error = TRUE)
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
})

test_that("remove_covr_hooks() removes only the onLoad hooks of covr", {
  event <- packageEvent("covrHooksTest", "onLoad")
  withr::defer(setHook(event, NULL, "replace"))
  other <- function(...) "other"
  setHook(event, other)
  setHook(event, function(...) options(covr.record_tests = FALSE))
  setHook(event, function(...) covr:::register_trace(ns, "dir"))

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
  run_with_library(pkgs$lib, "TestNestedOuter::outer_fun(1)")
  expect_length(list.files(traces), 0)
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
