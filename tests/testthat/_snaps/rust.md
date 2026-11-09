# Rust code coverage is skipped with a warning without the tools

    Code
      cov <- package_coverage("TestRust", relative_path = TRUE)
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x Can't find the Rust profiler runtime, llvm-cov, and llvm-profdata.
      i Install the llvm tools with `rustup component add llvm-tools`.
      i If Rust isn't installed with rustup, install those of LLVM 18.
      i Use `options(covr.llvm_cov = "")` to turn this off.

# Missing parts of the Rust toolchain are reported (#728)

    Code
      rust <- setup(rustc = "rustc", llvm_cov = "llvm-cov", llvm_profdata = "llvm-profdata")
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x Can't find the Rust profiler runtime.
      i Use `options(covr.llvm_cov = "")` to turn this off.
    Code
      rust <- setup(rustc = "rustc", rustup_toolchain = "1.88.0-x86_64-unknown-linux-gnu",
        profiler_runtime = "libprofiler_builtins.rlib")
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x Can't find llvm-cov and llvm-profdata.
      i Install the llvm tools with `rustup component add llvm-tools --toolchain 1.88.0-x86_64-unknown-linux-gnu`.
      i Use `options(covr.llvm_cov = "")` to turn this off.

# Only code compiled by the checked toolchain is instrumented (#728)

    Code
      expect_null(rust_check_build(rust))
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x It was compiled by '<dir>/pinned/rustc', from another toolchain than '<dir>/stable'.

---

    Code
      expect_null(rust_check_build(rust))
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x cargo didn't compile it, e.g. because the package used a prebuilt library.

# Rust code coverage is skipped with a warning if llvm-cov fails

    Code
      cov <- package_coverage("TestRust", relative_path = TRUE)
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x 'false' failed with exit status 1.

