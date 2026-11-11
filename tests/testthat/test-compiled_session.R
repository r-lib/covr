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

  expect_snapshot(
    with_coverage(
      {
        ns$simple(1)
        stop("boom")
      },
      env = ns
    ),
    error = TRUE
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

test_that("environment_coverage() measures Rust code of load_all()ed packages (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  path <- local_rust_package()
  script <- local_rust_test_script()

  cov <- environment_coverage(asNamespace("TestRust"), script)

  expect_setequal(
    unique(as.data.frame(cov)$filename),
    file.path(path, c("R/TestRust.R", "src/wrapper.c", "src/rust/src/lib.rs"))
  )
  expect_equal(
    compiled_counts(cov, "lib.rs"),
    c(`2` = 3, `3` = 3, `4` = 2, `5` = 1, `6` = 1, `8` = 0)
  )

  lib_rs <- file.path(path, "src", "rust", "src", "lib.rs")
  writeLines(c("// A new first line", readLines(lib_rs)), lib_rs)
  ns <- pkgload::load_all(path, quiet = TRUE)$env
  edited <- environment_coverage(ns, script)

  expect_equal(
    compiled_counts(edited, "lib.rs"),
    c(`3` = 3, `4` = 3, `5` = 2, `6` = 1, `7` = 1, `9` = 0)
  )
})

test_that("file_coverage() measures Rust files of a package (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  path <- local_rust_package()
  pkgload::unload("TestRust")
  lib_rs <- file.path(path, "src", "rust", "src", "lib.rs")

  cov <- file_coverage(lib_rs, local_rust_test_script())

  expect_equal(unique(as.data.frame(cov)$filename), lib_rs)
  expect_equal(compiled_counts(cov, "lib.rs")[["8"]], 0)
})

test_that("Rust code is measured when its DLL can't be unloaded (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  # A thread-local variable with a destructor keeps the DLL loaded on Linux,
  # as Rust code always does on macOS
  local_rust_package(
    lib_rs = c(
      "use std::cell::RefCell;",
      "",
      "thread_local! {",
      "    static CALLS: RefCell<Vec<i32>> = RefCell::new(Vec::new());",
      "}",
      "",
      "#[no_mangle]",
      "pub extern \"C\" fn rust_sign(x: i32) -> i32 {",
      "    CALLS.with(|calls| calls.borrow_mut().push(x));",
      "    if x > 0 {",
      "        1",
      "    } else {",
      "        -1",
      "    }",
      "}"
    )
  )
  ns <- asNamespace("TestRust")
  script <- local_rust_test_script()

  first <- environment_coverage(ns, script)
  second <- environment_coverage(ns, script)

  expect_equal(
    compiled_counts(first, "lib.rs")[c("11", "13")],
    c(2, 1),
    ignore_attr = TRUE
  )
  expect_equal(
    compiled_counts(second, "lib.rs"),
    compiled_counts(first, "lib.rs")
  )
})

test_that("Rust code in the session is skipped with a warning without the tools (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  local_rust_package()
  ns <- asNamespace("TestRust")
  script <- local_rust_test_script()
  local_mocked_bindings(
    rust_toolchain = function(dir) list(rustc = "rustc", llvm_version = "18")
  )

  expect_snapshot(cov <- environment_coverage(ns, script))
  expect_setequal(
    unique(basename(as.data.frame(cov)$filename)),
    c("TestRust.R", "wrapper.c")
  )

  withr::local_options(covr.llvm_cov = "")
  expect_no_warning(cov <- environment_coverage(ns, script))
  expect_setequal(
    unique(basename(as.data.frame(cov)$filename)),
    c("TestRust.R", "wrapper.c")
  )
})

test_that("Rust code in the session is skipped with a warning if llvm-cov fails (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  false <- unname(Sys.which("false"))
  skip_if(!nzchar(false))
  local_rust_package()
  # Nothing else is measured in the DLL
  withr::local_options(covr.gcov = "", covr.llvm_cov = false)

  expect_snapshot(
    cov <- environment_coverage(
      asNamespace("TestRust"),
      local_rust_test_script()
    )
  )
  expect_equal(unique(basename(as.data.frame(cov)$filename)), "TestRust.R")
})

test_that("Rust code in the session is skipped if its build wasn't instrumented (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  local_rust_package()
  withr::local_options(covr.gcov = "")
  local_mocked_bindings(rust_check_build = function(rust) NULL)

  cov <- environment_coverage(
    asNamespace("TestRust"),
    local_rust_test_script()
  )
  expect_equal(unique(basename(as.data.frame(cov)$filename)), "TestRust.R")
})

test_that("file_coverage() requires gcov for C files of a package with Rust code (#749)", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  skip_if_not_installed("pkgload")
  path <- local_rust_package()
  withr::local_options(covr.gcov = NA_character_)

  expect_snapshot(
    file_coverage(file.path(path, "src", "wrapper.c"), character()),
    error = TRUE
  )
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
    build_instrumented_copy = function(path, build, rust) {
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

test_that("the copy of a package with Rust code leaves cargo's files alone (#749)", {
  pkg <- withr::local_tempdir()
  files <- c(
    "DESCRIPTION",
    "src/init.o",
    "src/rust/Cargo.toml",
    "src/rust/target/CACHEDIR.TAG",
    "src/rust/target/release/libpkg.a",
    "src/rust/vendor/windows/lib/libwindows.a",
    "src/rust/vendor/cc/src/target/apple.rs",
    # A `target` directory by another name, e.g. with `--target-dir`
    "src/rust/cargo-build/CACHEDIR.TAG",
    "src/rust/cargo-build/release/build/dep/out/libdep.a"
  )
  for (file in file.path(pkg, files)) {
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    file.create(file)
  }

  expect_setequal(
    package_copy_files(pkg),
    c(
      "DESCRIPTION",
      "src/rust/Cargo.toml",
      "src/rust/vendor/windows/lib/libwindows.a",
      "src/rust/vendor/cc/src/target/apple.rs"
    )
  )
  expect_equal(build_outputs(pkg), file.path(pkg, "src/init.o"))
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

  expect_no_match(
    instrumented_dll[["path"]],
    original_dll[["path"]],
    fixed = TRUE
  )
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

test_that("sync_package_copy() returns the files that changed or were removed", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")

  sync <- sync_package_copy(path, build)
  expect_setequal(
    sync$changed,
    c("DESCRIPTION", "R/pkg.R", "src/a.c", "src/b.c", "src/util.h")
  )
  expect_equal(sync$removed, character())
  expect_equal(
    readLines(file.path(build, "src", "a.c")),
    readLines(file.path(path, "src", "a.c"))
  )

  expect_equal(sync_package_copy(path, build)$changed, character())

  writeLines("int a() { return 11; }", file.path(path, "src", "a.c"))
  unlink(file.path(path, "src", "b.c"))
  sync <- sync_package_copy(path, build)
  expect_equal(sync$changed, "src/a.c")
  expect_equal(sync$removed, "src/b.c")
  expect_equal(
    readLines(file.path(build, "src", "a.c")),
    "int a() { return 11; }"
  )
  expect_no_match(list.files(file.path(build, "src")), "^b\\.c$")
})

test_that("sync_package_copy() copies a replaced file with an older time", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  a <- file.path(path, "src", "a.c")
  sync_package_copy(path, build)

  # Same size, but older than both the previous source and its copy
  mtime <- file.mtime(a)
  writeLines("int a() { return 7; }", a)
  Sys.setFileTime(a, mtime - 3600)

  expect_equal(sync_package_copy(path, build)$changed, "src/a.c")
  expect_equal(
    readLines(file.path(build, "src", "a.c")),
    "int a() { return 7; }"
  )
})

test_that("sync_package_copy() copies a file that was deleted from the copy", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  sync_package_copy(path, build)
  unlink(file.path(build, "src", "a.c"))

  expect_equal(sync_package_copy(path, build)$changed, "src/a.c")
  expect_contains(list.files(file.path(build, "src")), "a.c")
})

test_that("build_instrumented_copy() only compiles when the package changes", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()

  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)

  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)

  # R code doesn't change the DLL
  writeLines("f <- function() 2", file.path(path, "R", "pkg.R"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)
})

test_that("build_instrumented_copy() keeps the objects when a source changes", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)

  writeLines("int a() { return 11; }", file.path(path, "src", "a.c"))
  build_instrumented_copy(path, build)

  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, FALSE)
  expect_setequal(state$calls[[2]]$outputs, c("a.o", "b.o", "pkg.so"))
})

test_that("build_instrumented_copy() rebuilds everything when a header changes", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)

  writeLines("#define X 2", file.path(path, "src", "util.h"))
  build_instrumented_copy(path, build)

  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, TRUE)
  expect_equal(state$calls[[2]]$outputs, character())
})

test_that("build_instrumented_copy() rebuilds when native inputs are deleted", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)

  unlink(file.path(path, "src", "b.c"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, TRUE)
  expect_equal(state$calls[[2]]$outputs, character())
  expect_no_match(list.files(file.path(build, "src")), "^b\\.(c|o)$")

  unlink(file.path(path, "src", "util.h"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 3)
  expect_equal(state$calls[[3]]$force, TRUE)
  expect_equal(state$calls[[3]]$outputs, character())
})

test_that("build_instrumented_copy() doesn't rebuild when other files are deleted", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)

  unlink(file.path(path, "R", "pkg.R"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)
})

test_that("build_instrumented_copy() rebuilds when covr.flags change", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  state <- mock_compile_instrumented()
  flags <- getOption("covr.flags")
  withr::local_options(covr.flags = flags)
  build_instrumented_copy(path, build)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)

  options(covr.flags = c(flags, CPPFLAGS = "-DCOVR_TEST"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, TRUE)
  expect_equal(state$calls[[2]]$outputs, character())

  build_instrumented_copy(path, build)
  expect_length(state$calls, 2)

  options(covr.flags = flags)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 3)
})

test_that("build_instrumented_copy() rebuilds when the user's Makevars change", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  makevars <- withr::local_tempfile()
  writeLines("CFLAGS = -O1", makevars)
  withr::local_envvar(R_MAKEVARS_USER = makevars)
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)

  writeLines("CFLAGS = -O2", makevars)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, TRUE)
})

test_that("build_instrumented_copy() rebuilds when configure changes", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  configure <- file.path(path, "configure")
  writeLines("#!/bin/sh", configure)
  state <- mock_compile_instrumented()
  build_instrumented_copy(path, build)
  expect_length(state$calls, 1)

  writeLines(c("#!/bin/sh", "echo config"), configure)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 2)
  expect_equal(state$calls[[2]]$force, TRUE)
  expect_equal(state$calls[[2]]$outputs, character())

  # The same size, with an older time
  mtime <- file.mtime(configure)
  writeLines(c("#!/bin/sh", "echo CONFIG"), configure)
  Sys.setFileTime(configure, mtime - 3600)
  build_instrumented_copy(path, build)
  expect_length(state$calls, 3)
  expect_equal(state$calls[[3]]$force, TRUE)

  writeLines("#!/bin/sh", file.path(path, "configure.win"))
  build_instrumented_copy(path, build)
  expect_length(state$calls, 4)
  expect_equal(state$calls[[4]]$force, TRUE)
})

test_that("a failed build is compiled again", {
  path <- local_native_package()
  build <- file.path(withr::local_tempdir(), "build")
  calls <- 0
  local_mocked_bindings(
    compile_instrumented = function(build, flags, env, force = FALSE) {
      calls <<- calls + 1
      stop("compile error")
    }
  )

  expect_snapshot(build_instrumented_copy(path, build), error = TRUE)
  expect_snapshot(build_instrumented_copy(path, build), error = TRUE)
  expect_equal(calls, 2)
})

test_that("compiled coverage is rebuilt when covr.flags change", {
  skip_on_cran()
  skip_if(is_win_r41())
  skip_if_not_installed("pkgload")
  path <- local_compiled_package()
  script <- local_compiled_test_script()
  ns <- asNamespace("TestCompiled")
  dll <- file.path(
    temp_dir(),
    "covr_compiled",
    paste0("TestCompiled-", substr(digest::digest(path), 1, 8)),
    "src",
    paste0("TestCompiled", .Platform$dynlib.ext)
  )

  environment_coverage(ns, script)
  first <- file.mtime(dll)

  # The flags only change how the code is compiled
  withr::local_options(
    covr.flags = c(getOption("covr.flags"), CPPFLAGS = "-DCOVR_TEST_FLAG")
  )
  Sys.sleep(1.1)
  environment_coverage(ns, script)
  expect_gt(file.mtime(dll), first)
})
