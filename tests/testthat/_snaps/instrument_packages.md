# trace_coverage() warns and returns no coverage without any traces

    Code
      cov <- trace_coverage(".")
    Condition
      Warning:
      Can't find the coverage of any instrumented package in '.'.

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

