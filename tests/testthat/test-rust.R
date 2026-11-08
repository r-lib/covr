test_that("Rust code coverage is reported (#728)", {
  skip_on_cran()
  skip_if_no_rust_coverage()

  cov <- as.data.frame(package_coverage("TestRust", relative_path = TRUE))
  expect_setequal(
    unique(cov$filename),
    c("R/TestRust.R", "src/wrapper.c", "src/rust/src/lib.rs")
  )

  lib_rs <- cov[cov$filename == "src/rust/src/lib.rs", ]
  expect_equal(
    stats::setNames(lib_rs$value, lib_rs$first_line),
    c(`2` = 3, `3` = 3, `4` = 2, `5` = 1, `6` = 1, `8` = 0, `10` = 3)
  )
})

test_that("covr.llvm_cov = '' turns off Rust code coverage", {
  skip_on_cran()
  skip_if_no_rust_coverage()

  withr::local_options(covr.llvm_cov = "")
  cov <- as.data.frame(package_coverage("TestRust", relative_path = TRUE))
  expect_setequal(unique(cov$filename), c("R/TestRust.R", "src/wrapper.c"))
})

test_that("Rust code coverage is skipped with a warning without the tools", {
  skip_on_cran()
  skip_if_no_rust_coverage()

  local_mocked_bindings(
    rust_toolchain = function(dir) list(rustc = "rustc", llvm_version = "18")
  )
  expect_snapshot(
    cov <- package_coverage("TestRust", relative_path = TRUE)
  )
  expect_setequal(
    unique(as.data.frame(cov)$filename),
    c("R/TestRust.R", "src/wrapper.c")
  )
})

test_that("Missing parts of the Rust toolchain are reported (#728)", {
  skip_on_os("windows")
  setup <- function(...) {
    local_mocked_bindings(rust_toolchain = function(dir) list(...))
    rust_coverage_setup(test_path("TestRust"), withr::local_tempdir())
  }
  expect_snapshot({
    rust <- setup(
      rustc = "rustc",
      llvm_cov = "llvm-cov",
      llvm_profdata = "llvm-profdata"
    )
    # e.g. the toolchain pinned by a package's `rust-toolchain.toml`
    rust <- setup(
      rustc = "rustc",
      rustup_toolchain = "1.88.0-x86_64-unknown-linux-gnu",
      profiler_runtime = "libprofiler_builtins.rlib"
    )
  })
  expect_null(rust)
})

test_that("Only code compiled by the checked toolchain is instrumented (#728)", {
  skip_on_os("windows")
  dir <- withr::local_tempdir()
  # A rustc that prints its sysroot, or the arguments it compiles with
  fake_rustc <- function(toolchain) {
    sysroot <- file.path(dir, toolchain)
    dir.create(sysroot)
    rustc <- file.path(sysroot, "rustc")
    writeLines(
      c(
        "#!/bin/sh",
        sprintf(
          "if [ \"$1\" = --print ]; then echo %s; else echo \"$@\"; fi",
          shQuote(sysroot)
        )
      ),
      rustc
    )
    Sys.chmod(rustc, "755")
    rustc
  }
  stable <- fake_rustc("stable")
  pinned <- fake_rustc("pinned")
  rust <- list(build_dir = file.path(dir, "build"), sysroot = dirname(stable))
  dir.create(rust$build_dir)
  wrapper <- rust_coverage_wrapper(rust$build_dir, rust$sysroot)
  compile <- function(rustc) {
    system2(wrapper, c(rustc, "--crate-name", "pkg"), stdout = TRUE)
  }

  expect_equal(compile(pinned), "--crate-name pkg")
  expect_snapshot(
    expect_null(rust_check_build(rust)),
    transform = function(x) gsub(dir, "<dir>", x, fixed = TRUE)
  )

  dir.create(rust$build_dir)
  wrapper <- rust_coverage_wrapper(rust$build_dir, rust$sysroot)
  expect_equal(compile(stable), "--crate-name pkg -C instrument-coverage")
  expect_equal(rust_check_build(rust), rust)

  # cargo didn't compile anything, e.g. because of a prebuilt library
  dir.create(rust$build_dir)
  expect_snapshot(expect_null(rust_check_build(rust)))
})

test_that("The system's llvm tools need rustc's LLVM version (#728)", {
  skip_on_os("windows")
  bin <- withr::local_tempdir()
  tool <- function(name, version) {
    path <- file.path(bin, name)
    writeLines(c("#!/bin/sh", paste("echo", shQuote(version))), path)
    Sys.chmod(path, "755")
    path
  }
  withr::local_envvar(PATH = bin)

  llvm_cov <- tool("llvm-cov", "Ubuntu LLVM version 17.0.6")
  expect_equal(system_llvm_tool("llvm-cov", "17"), llvm_cov)
  expect_null(system_llvm_tool("llvm-cov", "18"))

  llvm_cov_18 <- tool("llvm-cov-18", "Ubuntu LLVM version 18.1.3")
  expect_equal(system_llvm_tool("llvm-cov", "18"), llvm_cov_18)
  expect_null(system_llvm_tool("llvm-cov", NA_character_))
})

test_that("Rust code coverage is skipped with a warning if llvm-cov fails", {
  skip_on_cran()
  skip_if_no_rust_coverage()
  false <- unname(Sys.which("false"))
  skip_if(!nzchar(false))

  withr::local_options(covr.llvm_cov = false)
  expect_snapshot(
    cov <- package_coverage("TestRust", relative_path = TRUE)
  )
  expect_setequal(
    unique(as.data.frame(cov)$filename),
    c("R/TestRust.R", "src/wrapper.c")
  )
})

test_that("parse_lcov keeps the package's own Rust files (#728)", {
  # The package is in a `vendor` directory, which only counts for directories
  # inside the package
  pkg <- file.path(withr::local_tempdir(), "vendor", "pkg")
  files <- file.path(
    pkg,
    "src",
    c(
      "rust/src/lib.rs",
      "rust/vendor/dep/src/lib.rs",
      "rust/target/release/build/out/generated.rs",
      ".cargo/registry/src/dep/src/lib.rs"
    )
  )
  for (file in files) {
    dir.create(dirname(file), recursive = TRUE)
    writeLines(paste("line", 1:4), file)
  }
  pkg <- normalize_path(pkg)
  files <- normalize_path(files)
  outside <- withr::local_tempfile(lines = paste("line", 1:4))

  record <- function(file, ...) c(paste0("SF:", file), ..., "end_of_record")
  lcov <- c(
    record(outside, "DA:1,1"),
    record(
      files[[1]],
      "FN:1,_RNvCs1_3pkg1f",
      "FNDA:2,_RNvCs1_3pkg1f",
      "DA:1,2",
      "DA:2,0",
      "DA:4,10000000000",
      "LF:3",
      "LH:2"
    ),
    record(files[[2]], "DA:1,5"),
    record(files[[3]], "DA:1,5"),
    record(files[[4]], "DA:1,5")
  )

  res <- parse_lcov(lcov, package_path = pkg)
  expect_equal(
    stats::setNames(
      vdapply(res, function(x) x$value),
      viapply(res, function(x) x$srcref[[1]])
    ),
    c(`1` = 2, `2` = 0, `4` = 1e10)
  )
  expect_equal(
    unique(vcapply(res, function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    })),
    files[[1]]
  )
})

test_that("The C code of vendored crates isn't included (#728)", {
  pkg <- file.path(withr::local_tempdir(), "vendor", "pkg")
  files <- file.path(
    pkg,
    "src",
    c(
      "wrapper.c",
      "rust/vendor/savvy/src/unwind_protect_wrapper.c",
      "vendor/dep/src/dep.c",
      "rust/target/release/build/dep/out/generated.c"
    )
  )
  for (file in files) {
    dir.create(dirname(file), recursive = TRUE)
    writeLines("line 1", file)
  }
  files <- normalize_path(files)
  coverage <- unlist(
    lapply(files, function(file) {
      line_coverages(file, list(line = 1), 1, NA_character_)
    }),
    recursive = FALSE
  )

  res <- drop_rust_dependencies(coverage, roots = normalize_path(pkg))
  expect_equal(
    unname(vcapply(res, function(x) {
      get_source_filename(x$srcref, full.names = TRUE)
    })),
    files[[1]]
  )
})

test_that("Cleaning the objects keeps cargo's build output (#728)", {
  pkg <- withr::local_tempdir()
  touch <- function(files) {
    files <- file.path(pkg, "src", files)
    for (file in files) {
      dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
      file.create(file)
    }
  }
  objects <- c("init.o", "vendor/lib/foo.o")
  cargo <- c(
    "rust/target/release/libpkg.a",
    "rust/target/release/build/savvy-1/out/libunwind_protect.a"
  )
  touch(c(objects, cargo))

  # Without Rust code, all objects are removed
  clean_objects(pkg)
  expect_equal(
    file.exists(file.path(pkg, "src", c(objects, cargo))),
    rep(FALSE, 4)
  )

  touch(c("rust/Cargo.toml", objects, cargo))
  clean_objects(pkg)
  expect_equal(
    file.exists(file.path(pkg, "src", c(objects, cargo))),
    c(FALSE, TRUE, TRUE, TRUE)
  )
})
