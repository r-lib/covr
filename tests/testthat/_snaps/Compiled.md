# Error thrown for missing gcov

    Code
      package_coverage("TestCompiled", relative_path = TRUE)
    Condition
      Error:
      ! Can't find gcov.
      i Set its path with `options(covr.gcov = )`.

# Warning thrown for empty gcov output

    Code
      . <- package_coverage("TestCompiled", relative_path = TRUE)
    Condition
      Warning:
      Can't find any coverage in the gcov output.

