# Clean and restructure counter tests for a coverage object

For tests produced with `options(covr.record_tests)`, prune any unused
records in the \$tests\$tally matrices of each trace and get rid of the
wrapping \$tests environment (reassigning with value of \$tests\$tally)

## Usage

``` r
as_coverage_with_tests(counters)
```

## Arguments

- counters:

  An environment of covr trace results to convert to a coverage object.
  If `counters` is not provided, the `covr` namespace value `.counters`
  is used.
