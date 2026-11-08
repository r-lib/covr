# Provide percent coverage of package

Calculate the total percent coverage from a coverage result object.

## Usage

``` r
percent_coverage(x, ...)
```

## Arguments

- x:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- ...:

  additional arguments passed to
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md),
  such as `by = "branch"` for the percentage of branches taken (see
  [covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)).

## Value

The total percentage as a `numeric(1)`.
