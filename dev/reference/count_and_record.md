# increment a given counter and record the test that hit it

Used instead of
[`count()`](https://covr.r-lib.org/dev/reference/count.md) in code
instrumented with `options(covr.record_tests = TRUE)`.

## Usage

``` r
count_and_record(key)
```

## Arguments

- key:

  generated with [`key()`](https://covr.r-lib.org/dev/reference/key.md)
