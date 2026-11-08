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

  cov <- with_coverage(ns$simple4(3L), env = ns)
  expect_equal(compiled_counts(cov, "simple4.cc"), c(`7` = 1, `8` = 1))

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

test_that("file_coverage() requires compiled files to be in one package", {
  skip_if_not_installed("pkgload")
  withr::local_dir(withr::local_tempdir())
  writeLines("int x;", "foo.c")

  expect_snapshot(file_coverage("foo.c", character()), error = TRUE)
})
