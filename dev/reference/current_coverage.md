# Coverage measured so far in the current process

`current_coverage()` returns the coverage that instrumented code has
recorded so far in the current R process. Call it from code that covr
runs, such as the `code` of
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
or
[`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md),
to measure the coverage of parts of a run, e.g. of each test file in
turn.

## Usage

``` r
current_coverage(reset = FALSE)
```

## Arguments

- reset:

  If `TRUE`, set the counts of all traces to zero after reading them, so
  the next call only includes code run after this one. The coverage
  returned at the end of the run then also only includes code run after
  the last reset.

## Value

A [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object,
with no traces if no code was instrumented.

## Details

Only the current process is included: code run in other processes, e.g.
by [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html),
is added to the coverage that covr returns at the end of the run, but
not to that of `current_coverage()`. No exclusions are applied.

## Examples

``` r
env <- new.env()
code <- "f <- function(x) {
  if (x) {
    'yes'
  } else {
    'no'
  }
}"
eval(parse(text = code, keep.source = TRUE), env)
with_coverage(
  {
    env$f(TRUE)
    first <- current_coverage(reset = TRUE)
    env$f(FALSE)
    second <- current_coverage()
  },
  env = env
)
#> Coverage: 66.67%
#> <text>: 66.67%
tally_coverage(first)
#>   filename functions line value
#> 1   <text>         f    2     1
#> 2   <text>         f    3     1
#> 3   <text>         f    5     0
tally_coverage(second)
#>   filename functions line value
#> 1   <text>         f    2     1
#> 2   <text>         f    3     0
#> 3   <text>         f    5     1
```
