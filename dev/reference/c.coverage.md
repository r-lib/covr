# Combine coverage objects

Combine the coverage of several runs, e.g. of tests in different
directories, into a single coverage object. The counts of traces present
in more than one object are added, and traces only in some of the
objects are appended. Tests recorded with
`options(covr.record_tests = TRUE)` are combined as well.

## Usage

``` r
# S3 method for class 'coverage'
c(...)
```

## Arguments

- ...:

  Coverage objects, e.g. from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  or
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md).
  They must all be for the same package, or all have no package, like
  the results of
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
  and
  [`code_coverage()`](https://covr.r-lib.org/dev/reference/code_coverage.md).
  `NULL` arguments are dropped.

## Value

A coverage object.

## Details

The result keeps the attributes of the first object, such as the package
and root used for relative paths, except that the lines excluded from
line coverage are the union of the excluded lines of all objects. As
with `package_coverage(type = c("tests", "examples"))`, the result only
has a `type` if all objects have the same `type`.

As with any S3 method for [`c()`](https://rdrr.io/r/base/c.html), this
method is only used when the first argument is a coverage object.

## Examples

``` r
source_file <- tempfile(fileext = ".R")
writeLines(
  c(
    "add <- function(x, y) {",
    "  x + y",
    "}",
    "subtract <- function(x, y) {",
    "  x - y",
    "}"
  ),
  source_file
)
add_test <- tempfile(fileext = ".R")
writeLines("add(1, 2)", add_test)
subtract_test <- tempfile(fileext = ".R")
writeLines("subtract(2, 1)", subtract_test)

add_cov <- file_coverage(source_file, add_test)
subtract_cov <- file_coverage(source_file, subtract_test)
percent_coverage(add_cov)
#> [1] 50
percent_coverage(c(add_cov, subtract_cov))
#> [1] 100
```
