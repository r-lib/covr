# Determine if code is being run in covr

covr functions set the environment variable `R_COVR` to `"true"` while
they are running. `in_covr()` returns `TRUE` if the environment variable
is exactly `"true"` and `FALSE` otherwise, e.g. to skip tests that don't
work while measuring coverage.

## Usage

``` r
in_covr()
```

## Value

A single `TRUE` or `FALSE`.

## Examples

``` r
testthat::skip_if(in_covr())
```
