# Convert a coverage object to a data frame

Convert a coverage object to a data frame

## Usage

``` r
# S3 method for class 'coverage'
as.data.frame(x, row.names = NULL, optional = FALSE, sort = TRUE, ...)
```

## Arguments

- x:

  a [coverage](https://covr.r-lib.org/dev/reference/coverage.md) object.

- row.names, optional:

  ignored, for compatibility with
  [`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

- sort:

  if `TRUE` (the default), sum the counts of identical expressions and
  sort the rows by file and position. If `FALSE`, there is one row for
  each element of `x`, in the same order.

- ...:

  ignored.

## Value

A data frame with one row for each traced expression of R code and each
line of compiled code, and the columns:

- `filename`: the source file, relative to the `root` attribute of `x`
  (the package directory, for
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md))
  if there is one.

- `functions`: the name of the function containing the expression, or
  `NA` for compiled code.

- `first_line`, `last_line`: the lines the expression starts and ends
  on.

- `first_byte`, `last_byte`: the bytes of those lines the expression
  starts and ends at.

- `first_column`, `last_column`: the columns the expression starts and
  ends at. These differ from the bytes when the line contains multibyte
  characters.

- `first_parsed`, `last_parsed`: the lines as seen by the parser. These
  differ from `first_line` and `last_line` when the source uses `#line`
  directives.

- `value`: the number of times the expression was executed.

Use
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
for one row for each line instead.

## Examples

``` r
cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
as.data.frame(cov)
#>                               filename functions first_line first_byte
#> 1 /tmp/RtmpTKPjy4/source.R19227a8fae00       add          1         25
#>   last_line last_byte first_column last_column first_parsed last_parsed value
#> 1         1        29           25          29            1           1     1
```
