# Calculate test coverage for sets of files

The files in `source_files` are first sourced into a new environment to
define functions to be checked. Then they are instrumented to track
coverage and the files in `test_files` are sourced.

## Usage

``` r
file_coverage(
  source_files,
  test_files,
  line_exclusions = NULL,
  function_exclusions = NULL,
  parent_env = parent.frame()
)
```

## Arguments

- source_files:

  Character vector of source files with function definitions to measure
  coverage

- test_files:

  Character vector of test files with code to test the functions

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

- parent_env:

  The parent environment to use when sourcing the files.

## Examples

``` r
# For the purpose of this example, save code containing code and tests to files
cat("add <- function(x, y) { x + y }", file="add.R")
cat("add(1, 2) == 3", file="add_test.R")

# Use file_coverage() to calculate test coverage
file_coverage(source_files = "add.R", test_files = "add_test.R")
#> Coverage: 100.00%
#> add.R: 100.00%

# cleanup
file.remove(c("add.R", "add_test.R"))
#> [1] TRUE TRUE
```
