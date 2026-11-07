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

A `data.frame`. With `by = "expression"` it is the same as
[`as.data.frame.coverage()`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md).
With `by = "line"` it has one row for each line of code (excluding blank
and comment lines of R code) and the columns `filename`, `functions`,
`line` and `value`, where `value` is the smallest execution count of the
expressions on that line, so a line only counts as covered if all its
expressions were run.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) {\n  if (x) 'yes' else 'no'\n}",
  "f(TRUE)"
)
tally_coverage(cov)
#>                              filename functions line value
#> 1 /tmp/RtmpbLxMqj/source.R1a89fd9a26c         f    2     0
tally_coverage(cov, by = "expression")
#>                              filename functions first_line first_byte last_line
#> 1 /tmp/RtmpbLxMqj/source.R1a89fd9a26c         f          2          7         2
#> 2 /tmp/RtmpbLxMqj/source.R1a89fd9a26c         f          2         10         2
#> 3 /tmp/RtmpbLxMqj/source.R1a89fd9a26c         f          2         21         2
#>   last_byte first_column last_column first_parsed last_parsed value
#> 1         7            7           7            2           2     1
#> 2        14           10          14            2           2     1
#> 3        24           21          24            2           2     0
```
