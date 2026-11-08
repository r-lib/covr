# Tally coverage by line, expression or function

Tally coverage by line, expression or function

## Usage

``` r
tally_coverage(x, by = c("line", "expression", "function"))
```

## Arguments

- x:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- by:

  whether to tally coverage by line, expression or function

## Value

A `data.frame`. With `by = "expression"` it is the same as
[`as.data.frame.coverage()`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md).
With `by = "line"` it has one row for each function on each line of code
(excluding blank lines, comments and lines with only punctuation such as
`}`) and the columns `filename`, `functions`, `line` and `value`, where
`value` is the smallest execution count of the expressions on that line,
so a line only counts as covered if all its expressions were run. An
expression spanning several lines, such as a loop, only counts for the
lines that none of the expressions inside it are on.
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
[`report()`](https://covr.r-lib.org/dev/reference/report.md) and the
other line based outputs count each line once, with the smallest count
of its functions.

With `by = "function"` it has one row for each top level R function and
the columns `filename`, `functions`, `first_line`, `last_line` and
`value`, where `first_line` and `last_line` span the function's traced
code and `value` is the largest execution count of its expressions, so a
function counts as covered if any of its code was run. Compiled code has
no function names, so it is left out.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) {\n  if (x) 'yes' else 'no'\n}\ng <- function() 1",
  "f(TRUE)"
)
tally_coverage(cov)
#>                               filename functions line value
#> 1 /tmp/RtmpNfOpkz/source.R18411a5d7717         f    2     0
#> 2 /tmp/RtmpNfOpkz/source.R18411a5d7717         g    4     0
tally_coverage(cov, by = "expression")
#>                               filename functions first_line first_byte
#> 1 /tmp/RtmpNfOpkz/source.R18411a5d7717         f          2          7
#> 2 /tmp/RtmpNfOpkz/source.R18411a5d7717         f          2         10
#> 3 /tmp/RtmpNfOpkz/source.R18411a5d7717         f          2         21
#> 4 /tmp/RtmpNfOpkz/source.R18411a5d7717         g          4          6
#>   last_line last_byte first_column last_column first_parsed last_parsed value
#> 1         2         7            7           7            2           2     1
#> 2         2        14           10          14            2           2     1
#> 3         2        24           21          24            2           2     0
#> 4         4        17            6          17            4           4     0
tally_coverage(cov, by = "function")
#>                               filename functions first_line last_line value
#> 1 /tmp/RtmpNfOpkz/source.R18411a5d7717         f          2         2     1
#> 2 /tmp/RtmpNfOpkz/source.R18411a5d7717         g          4         4     0
```
