test_that("environment_coverage() measures compiled code of load_all()ed packages (#605)", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  path <- local_compiled_package()
  ns <- asNamespace("TestCompiled")
  original_dll <- getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]]

  cov <- environment_coverage(ns, local_compiled_test_script())

  simple <- compiled_counts(cov, "simple.cc")
  expect_equal(
    simple[c("10", "16", "19", "21")],
    c(4, 3, 0, 1),
    ignore_attr = TRUE
  )
  header <- compiled_counts(cov, "simple-header.h")
  expect_equal(header[c("12", "18", "21")], c(4, 3, 0), ignore_attr = TRUE)
  expect_setequal(
    unique(dirname(as.data.frame(cov)$filename)),
    file.path(path, c("R", "src"))
  )

  # The package's own DLL is restored and its source directory is untouched
  expect_equal(
    getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]],
    original_dll
  )
  expect_equal(ns$simple(-1), -1)
  expect_length(list.files(file.path(path, "src"), "[.]gc(no|da)$"), 0)
})

test_that("compiled coverage doesn't accumulate and follows changes to headers", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  path <- local_compiled_package()
  script <- local_compiled_test_script()

  first <- environment_coverage(asNamespace("TestCompiled"), script)
  second <- environment_coverage(asNamespace("TestCompiled"), script)
  expect_equal(
    compiled_counts(second, "simple.cc"),
    compiled_counts(first, "simple.cc")
  )

  header <- file.path(path, "src", "simple-header.h")
  writeLines(c("", readLines(header)), header)
  ns <- pkgload::load_all(path, quiet = TRUE)$env
  edited <- environment_coverage(ns, script)

  counts <- compiled_counts(edited, "simple-header.h")
  expect_equal(counts[c("13", "19", "22")], c(4, 3, 0), ignore_attr = TRUE)
})

test_that("with_coverage() measures compiled code and restores the DLL on error", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  local_compiled_package()
  ns <- asNamespace("TestCompiled")
  original_dll <- getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]]

  cov <- with_coverage(ns$simple(-1), env = ns)
  counts <- compiled_counts(cov, "simple.cc")
  expect_equal(counts[c("16", "19", "21")], c(0, 0, 1), ignore_attr = TRUE)

  expect_error(
    with_coverage(
      {
        ns$simple(1)
        stop("boom")
      },
      env = ns
    ),
    "boom"
  )
  expect_equal(
    getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]],
    original_dll
  )
  expect_equal(ns$simple(-1), -1)
})

test_that("compiled coverage works if loading the DLL assigns to the namespace", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  local_compiled_package("TestCompiledInit")
  ns <- asNamespace("TestCompiledInit")

  cov <- with_coverage(ns$sign_of(-1), env = ns)

  expect_equal(
    compiled_counts(cov, "init.c")[c("7", "9")],
    c(1, 0),
    ignore_attr = TRUE
  )
  expect_identical(bindingIsLocked(".loaded", ns), TRUE)
  expect_equal(ns$sign_of(2), 1L)
})

test_that("the package's DLL is restored if loading the instrumented one fails", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  local_compiled_package()
  ns <- asNamespace("TestCompiled")
  original_dll <- getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]]
  original_load <- load_namespace_dll
  local_mocked_bindings(load_namespace_dll = function(env, path) {
    if (grepl("covr_dll", path, fixed = TRUE)) {
      stop(errorCondition("Can't load.", class = "test_load_error"))
    }
    original_load(env, path)
  })

  expect_error(
    with_coverage(ns$simple(1), env = ns),
    class = "test_load_error"
  )
  expect_equal(
    getNamespaceInfo(ns, "DLLs")$TestCompiled[["path"]],
    original_dll
  )
  expect_equal(ns$simple(-1), -1)
})

test_that("file_coverage() measures compiled files of a package (#605)", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  path <- local_compiled_package()
  pkgload::unload("TestCompiled")

  cov <- file_coverage(
    file.path(path, "src", "simple.cc"),
    local_compiled_test_script()
  )

  expect_equal(
    unique(as.data.frame(cov)$filename),
    file.path(path, "src", "simple.cc")
  )
  expect_equal(compiled_counts(cov, "simple.cc")[["16"]], 3)
})

test_that("covr.gcov = '' turns off compiled code coverage in the session", {
  skip_on_cran()
  skip_if_not_installed("pkgload")
  local_compiled_package()
  withr::local_options(covr.gcov = "")

  cov <- environment_coverage(
    asNamespace("TestCompiled"),
    local_compiled_test_script()
  )

  expect_equal(unique(basename(as.data.frame(cov)$filename)), "TestCompiled.R")
})

test_that("compiled coverage is only measured for load_all()ed packages", {
  skip_if_not_installed("pkgload")

  expect_null(start_compiled_coverage(asNamespace("stats")))
})

test_that("compiled coverage requires the package to have compiled code", {
  skip_if_not_installed("pkgload")
  local_compiled_package("TestSummary")
  ns <- asNamespace("TestSummary")

  expect_null(start_compiled_coverage(ns))
  expect_snapshot(start_compiled_coverage(ns, required = TRUE), error = TRUE)
})

test_that("compiled coverage handles a build without the package's DLLs", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  local_compiled_package()
  ns <- asNamespace("TestCompiled")
  dll_dir <- NULL
  local_mocked_bindings(
    build_instrumented_copy = function(path, build) {
      dll_dir <<- temp_dir_create("covr_dll")
      dll_dir
    }
  )

  expect_null(suppressWarnings(start_compiled_coverage(ns)))
  expect_false(dir.exists(dll_dir))
  expect_snapshot(
    suppressWarnings(start_compiled_coverage(ns, required = TRUE)),
    error = TRUE
  )
  expect_false(dir.exists(dll_dir))
})

test_that("has_gcov() looks for gcov unless covr.gcov is set", {
  withr::local_options(covr.gcov = NULL)
  local_mocked_bindings(find_gcov = function() "/usr/bin/gcov")
  expect_true(has_gcov(FALSE))

  withr::local_options(covr.gcov = "")
  expect_false(has_gcov(FALSE))

  withr::local_options(covr.gcov = NA_character_)
  expect_false(has_gcov(FALSE))
  expect_snapshot(has_gcov(TRUE), error = TRUE)
})

test_that("read_rbuildignore() drops blank lines and comments", {
  path <- withr::local_tempdir()
  expect_equal(read_rbuildignore(path), character())

  writeLines(
    c("^docs$", "", "# a comment", "  ", "  ^[.]github  "),
    file.path(path, ".Rbuildignore")
  )
  expect_equal(read_rbuildignore(path), c("^docs$", "^[.]github"))
})

test_that("dll_bindings() finds the bindings that refer to the DLL", {
  skip_on_cran()
  skip_if_not_installed("pkgload")
  local_compiled_package_with_bindings()
  ns <- asNamespace("TestCompiled")

  expect_setequal(
    dll_bindings(ns, "TestCompiled"),
    c("dllinfo", "simple_", "simple3_", "simple4_", "unrecorded_routine")
  )
})

test_that("compiled coverage replaces the DLL object and routines in the namespace", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  local_compiled_package_with_bindings()
  ns <- asNamespace("TestCompiled")
  original_dll <- ns$dllinfo
  instrumented_dll <- NULL

  cov <- with_coverage(
    {
      instrumented_dll <- ns$dllinfo
      ns$simple(-1)
    },
    env = ns
  )

  expect_false(identical(instrumented_dll[["path"]], original_dll[["path"]]))
  expect_identical(ns$dllinfo[["path"]], original_dll[["path"]])
  expect_equal(compiled_counts(cov, "simple.cc")[["21"]], 1)
})

test_that("file_coverage() requires pkgload for compiled code", {
  local_mocked_bindings(is_installed = function(pkg) FALSE)
  expect_snapshot(file_coverage("foo.c", character()), error = TRUE)
})

test_that("file_coverage() requires compiled files to be in one package", {
  skip_if_not_installed("pkgload")
  withr::local_dir(withr::local_tempdir())
  writeLines("int x;", "foo.c")

  expect_snapshot(file_coverage("foo.c", character()), error = TRUE)
})
