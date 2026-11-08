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

# A missing profiler runtime is reported (#728)

    Code
      rust <- rust_coverage_setup(test_path("TestRust"), "rust/Cargo.toml", withr::local_tempdir())
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x Can't find the Rust profiler runtime.
      i Use `options(covr.llvm_cov = "")` to turn this off.

# Rust code coverage is skipped with a warning if llvm-cov fails

    Code
      cov <- package_coverage("TestRust", relative_path = TRUE)
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x 'false' failed with exit status 1.

