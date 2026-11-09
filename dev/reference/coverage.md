# Coverage objects

[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md),
[`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md),
[`code_coverage()`](https://covr.r-lib.org/dev/reference/code_coverage.md),
[`function_coverage()`](https://covr.r-lib.org/dev/reference/function_coverage.md)
and
[`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)
return a `coverage` object, which records how many times each part of
the code was executed.

## Working with coverage objects

Rather than using the list directly, you will usually want to:

- Get a data frame with one row for each expression with
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  ([`as.data.frame.coverage()`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md)),
  or one row for each line or function with
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md).

- Get the overall percentage with
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
  or the percentage for each file with
  [`coverage_to_list()`](https://covr.r-lib.org/dev/reference/coverage_to_list.md).

- Find the lines or functions which were never run with
  [`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md).

- Get the execution counts as a named numeric vector with
  [`value()`](https://covr.r-lib.org/dev/reference/value.md).

- Browse the coverage with
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) or
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md).

## Structure

A `coverage` object is a named list with one element for each traced
expression of R code and each line of compiled code. Each element is a
list with:

- `value`: the number of times the expression or line was executed.

- `srcref`: a [srcref](https://rdrr.io/r/base/srcfile.html) with its
  location. Its `srcfile` attribute holds the name and lines of the
  source file.

- `functions`: the name of the function containing it, or `NA` for
  compiled code.

- `tests`: only present with `options(covr.record_tests = TRUE)`, see
  [covr.record_tests](https://covr.r-lib.org/dev/reference/covr.record_tests.md).

The names of the elements are the base name of the file followed by the
eight numbers of the srcref, separated by `:`. For example
`foo.R:10:3:12:4:3:4:10:12` is an expression from line 10 column 3 to
line 12 column 4 of `foo.R` (see
[`as.data.frame.coverage()`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md)
for the meaning of each number). The `srcfile` of the `srcref`, or the
`filename` column of
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html), gives
the path of the file.

Coverage objects from
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
also have the attributes `package` (information about the package, such
as its `package` name and `path`), `root` (the directory file names are
relative to, or `NULL`) and, if `clean = FALSE`, `library` (the
`install_path`).

With `options(covr.record_tests = TRUE)`, coverage objects also have a
`tests` attribute with the test calls, see
[covr.record_tests](https://covr.r-lib.org/dev/reference/covr.record_tests.md).

With `options(covr.branch_coverage = TRUE)`, coverage objects also have
a `branches` attribute with the branches of each `if` and
[`switch()`](https://rdrr.io/r/base/switch.html), see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md).

## Examples

``` r
cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
cov
#> Coverage: 100.00%
#> /tmp/RtmpaZ8h5d/source.R185b650577b: 100.00%
as.data.frame(cov)
#>                              filename functions first_line first_byte last_line
#> 1 /tmp/RtmpaZ8h5d/source.R185b650577b       add          1         25         1
#>   last_byte first_column last_column first_parsed last_parsed value
#> 1        29           25          29            1           1     1
names(cov)
#> [1] "source.R185b650577b:1:25:1:29:25:29:1:1"
cov[[1]]$value
#> [1] 1
```
