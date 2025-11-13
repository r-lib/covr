# Provide locations of zero coverage

When examining the test coverage of a package, it is useful to know if
there are any locations where there is **0** test coverage.

## Usage

``` r
zero_coverage(x, ...)
```

## Arguments

- x:

  a coverage object returned
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- ...:

  additional arguments passed to
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)

## Value

A `data.frame` with coverage data where the coverage is 0.

## Details

if used within RStudio this function outputs the results using the
Marker API.
