# trace_coverage() warns and returns no coverage without any traces

    Code
      cov <- trace_coverage(".")
    Condition
      Warning:
      Can't find the coverage of any instrumented package in '.'.

# trace_coverage() gives the file names in the source directories in `paths`

    Code
      trace_coverage(traces, paths = function(files, package) NA_character_)
    Condition
      Error:
      ! `paths` must return a file name for each of the files of TestNestedOuter.
      x It returned `NA` for some of them.

# instrument_packages() errors for packages that are not installed or already instrumented

    Code
      instrument_packages("notapackage", "lib", traces)
    Condition
      Error:
      ! Can't find notapackage in the library 'lib'.

---

    Code
      instrument_packages(c("TestNestedOuter", "TestNestedOuter"), pkgs$lib)
    Condition
      Error:
      ! `packages` has TestNestedOuter more than once.

---

    Code
      instrument_packages(c("TestNestedInner", "TestNestedOuter"), pkgs$lib)
    Condition
      Error:
      ! TestNestedOuter is already instrumented.
      i Use `uninstrument_packages()` first.

# share_rust_profiles() leaves out packages built with another LLVM

    Code
      shared <- share_rust_profiles(rust)
    Condition
      Warning:
      Can't measure the coverage of the Rust code of b.
      x It may be built with another LLVM version than the Rust code of a (LLVM 18).
      i Measure the coverage of each of these packages on its own.

