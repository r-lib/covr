# Tally coverage by line or expression

Tally coverage by line or expression

## Usage

``` r
tally_coverage(x, by = c("line", "expression"))
```

## Arguments

- x:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- by:

  whether to tally coverage by line or expression

## Value

a `data.frame` of coverage tallied by line or expression.
