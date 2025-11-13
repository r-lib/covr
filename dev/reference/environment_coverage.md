# Calculate coverage of an environment

Calculate coverage of an environment

## Usage

``` r
environment_coverage(
  env = parent.frame(),
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL
)
```

## Arguments

- env:

  The environment to be instrumented.

- test_files:

  Character vector of test files with code to test the functions

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.
