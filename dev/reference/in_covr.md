# Determine if code is being run in covr

covr functions set the environment variable `R_COVR` when they are
running. `in_covr()` returns `TRUE` if this environment variable is set
and `FALSE` otherwise.

## Usage

``` r
in_covr()
```

## Examples

``` r
if (require(testthat)) {
  testthat::skip_if(in_covr())
}
#> Loading required package: testthat
```
