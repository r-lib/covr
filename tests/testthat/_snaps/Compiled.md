# Error thrown for missing gcov

    Code
      package_coverage("TestCompiled", relative_path = TRUE)
    Condition
      Error in `run_gcov()`:
      ! gcov not found

# Warning thrown for empty gcov output

    Code
      . <- package_coverage("TestCompiled", relative_path = TRUE)
    Condition
      Warning in `run_gcov()`:
      parsed gcov output was empty

