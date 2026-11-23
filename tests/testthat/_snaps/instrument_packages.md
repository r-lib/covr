# instrumented packages save their counts in COVR_TRACE_DIR if it is set

    Code
      trace_coverage(".")
    Condition
      Error:
      ! Can't find the coverage of any instrumented package in '.'.

# instrument_packages() errors for packages that are not installed or already instrumented

    Code
      instrument_packages("notapackage", "lib", traces)
    Condition
      Error:
      ! Can't find notapackage in the library 'lib'.

---

    Code
      instrument_packages(c("TestNestedInner", "TestNestedOuter"), pkgs$lib)
    Condition
      Error:
      ! TestNestedOuter is already instrumented.
      i Use `uninstrument_packages()` first.

