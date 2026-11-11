# Annotate source code with line and branch coverage

Produces plain text showing source lines together with their coverage
counts, in a form that is easy to read in a terminal or to paste into a
prompt. By default the missed lines are shown with `context` surrounding
lines.

## Usage

``` r
annotate_coverage(
  x,
  lines = NULL,
  context = 2,
  files = NULL,
  max_lines = getOption("covr.annotate_max_lines", 200)
)
```

## Arguments

- x:

  A coverage object, e.g. from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  or
  [`code_coverage()`](https://covr.r-lib.org/dev/reference/code_coverage.md).

- lines:

  A data frame with `filename` and `line` columns identifying the lines
  to show, e.g. the result of
  [`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md)
  or the lines changed in a pull request. Other columns are ignored. The
  default is all missed code lines in `x`, and the lines with a missed
  branch if branch coverage was measured.

- context:

  Number of lines to show before and after each line in `lines`. Use
  `Inf` to show whole files.

- files:

  Optional character vector of file names (as they appear in the
  coverage, e.g. `"R/foo.R"`) to restrict the output to.

- max_lines:

  The maximum number of source lines to show, 200 by default (option
  `covr.annotate_max_lines`). Whole chunks of lines are added until the
  next one would go over the limit, but the first chunk is always shown.
  If anything is left out, the last line says how many of the missed or
  requested lines in how many files are not shown. Use `Inf` for no
  limit.

## Value

A character vector of class `covr_annotation`, with one element per
output line. If there is nothing to show it is `"No missed lines."`.

## Details

Each shown line has the line number, a count column and the source.
Missed lines are marked `!!0`, covered code lines show their hit count,
and lines without coverage data (blank lines, comments, ...) have an
empty count. Non-adjacent chunks are separated by `...`.

If branch coverage was measured (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
lines with a branch that was not taken are also shown by default,
followed by `<- not taken:` and the labels of their missed branches.
Only `if` and [`switch()`](https://rdrr.io/r/base/switch.html) calls
that were evaluated count; the others are covered by the missed lines.
Such a line keeps its count if it was run.

## Examples

``` r
source <- "
f <- function(x) {
  if (x) {
    'yes'
  } else {
    'no'
  }
}
"
cov <- code_coverage(source, "f(TRUE)")
annotate_coverage(cov)
#> /tmp/RtmpgqK6Cl/source.R184f1ca285d7
#>   4 |    1 |     'yes'
#>   5 |      |   } else {
#>   6 |  !!0 |     'no'
#>   7 |      |   }
#>   8 |      | }
annotate_coverage(cov, context = Inf)
#> /tmp/RtmpgqK6Cl/source.R184f1ca285d7
#>   1 |      | 
#>   2 |      | f <- function(x) {
#>   3 |    1 |   if (x) {
#>   4 |    1 |     'yes'
#>   5 |      |   } else {
#>   6 |  !!0 |     'no'
#>   7 |      |   }
#>   8 |      | }
```
