# Calculate coverage of code directly

This function is useful for testing, and is a thin wrapper around
[`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
because parseData is not populated properly unless the functions are
defined in a file.

## Usage

``` r
code_coverage(
  source_code,
  test_code,
  line_exclusions = NULL,
  function_exclusions = NULL,
  ...
)
```

## Arguments

- source_code:

  A character vector of source code

- test_code:

  A character vector of test code

- line_exclusions:

  a named list of files with the lines to exclude from each file.

- function_exclusions:

  a vector of regular expressions matching function names to exclude.
  Example `print\\\.` to match print methods.

- ...:

  Additional arguments passed to
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)

## Examples

``` r
source <- "add <- function(x, y) { x + y }"
test <- "add(1, 2) == 3"
code_coverage(source, test)
#> Coverage: 100.00%
#> /tmp/RtmpaFzldN/source.R1ca8c593213: 100.00%
```
