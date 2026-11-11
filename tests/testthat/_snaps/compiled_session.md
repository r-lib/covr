# Rust code in the session is skipped with a warning without the tools (#749)

    Code
      cov <- environment_coverage(ns, script)
    Condition
      Warning:
      Can't measure the coverage of Rust code.
      x Can't find the Rust profiler runtime, llvm-cov, and llvm-profdata.
      i Install the llvm tools with `rustup component add llvm-tools`.
      i If Rust isn't installed with rustup, install those of LLVM 18.
      i Use `options(covr.llvm_cov = "")` to turn this off.

# compiled coverage requires the package to have compiled code

    Code
      start_compiled_coverage(ns, required = TRUE)
    Condition
      Error:
      ! Can't find compiled code loaded by TestSummary.

# compiled coverage handles a build without the package's DLLs

    Code
      suppressWarnings(start_compiled_coverage(ns, required = TRUE))
    Condition
      Error:
      ! Can't find the DLLs "TestCompiled" in the build of TestCompiled.

# has_gcov() looks for gcov unless covr.gcov is set

    Code
      has_gcov(TRUE)
    Condition
      Error:
      ! Can't find gcov.
      i Set its path with `options(covr.gcov = )`.

# file_coverage() requires pkgload for compiled code

    Code
      file_coverage("foo.c", character())
    Condition
      Error:
      ! `file_coverage()` requires pkgload for compiled code.

# file_coverage() requires compiled files to be in one package

    Code
      file_coverage("foo.c", character())
    Condition
      Error:
      ! Compiled `source_files` must be in a single package.
      i Can't find one package for 'foo.c'.

