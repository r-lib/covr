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
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md),
  such as `by = "function"` to list the functions that were never run.

## Value

A `data.frame` with coverage data where the coverage is 0.

## Details

if used within RStudio this function outputs the results using the
Marker API.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) {\n  if (x) 'yes' else 'no'\n}\ng <- function() 1",
  "f(TRUE)"
)
zero_coverage(cov)
#>                               filename functions line value
#> 1 /tmp/Rtmp2ceVqU/source.R19527921937c         f    2     0
#> 2 /tmp/Rtmp2ceVqU/source.R19527921937c         g    4     0
zero_coverage(cov, by = "function")
#>                               filename functions first_line last_line value
#> 2 /tmp/Rtmp2ceVqU/source.R19527921937c         g          4         4     0
```
