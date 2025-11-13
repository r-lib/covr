# Initialize a new test counter for a coverage trace

Initialize a test counter, a matrix used to tally tests, their stack
depth and the execution order as the trace associated with `key` is hit.
Each test trace is an environment, which allows assignment into a
pre-allocated `tests` matrix with minimall reallocation.

## Usage

``` r
new_test_counter(key)
```

## Arguments

- key:

  generated with [`key()`](https://covr.r-lib.org/dev/reference/key.md)

## Details

The `tests` matrix has columns `tests`, `depth` and `i`, corresponding
to the test index (the index of the associated test in
`.counters$tests`), the stack depth when the trace is evaluated and the
number of traces that have been hit so far during test evaluation.
