# Convert a counters object to a coverage object

Convert a counters object to a coverage object

## Usage

``` r
as_coverage(counters = NULL, ...)
```

## Arguments

- counters:

  An environment of covr trace results to convert to a coverage object.
  If `counters` is not provided, the `covr` namespace value `.counters`
  is used.

- ...:

  Additional attributes to include with the coverage object.
