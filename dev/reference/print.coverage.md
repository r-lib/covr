# Print a coverage object

Print a coverage object

## Usage

``` r
# S3 method for class 'coverage'
print(
  x,
  group = c("filename", "functions"),
  by = "line",
  n = Inf,
  missing = FALSE,
  ...
)
```

## Arguments

- x:

  the coverage object to be printed

- group:

  whether to group coverage by filename or function

- by:

  whether to count coverage by line, expression or function

- n:

  the maximum number of files or functions to print. They are sorted
  from least to most covered, so the least covered are shown first.

- missing:

  whether to list the lines that were not run after each file or
  function that has any, as ranges such as `missed 41-48, 112`. Lines
  are joined into a range when only blank lines, comments and lines with
  only punctuation, such as closing braces, are between them. Code that
  was run, or that has no coverage data, such as the line a function is
  defined on, ends the range. Only used with `by = "line"`, and ignored
  otherwise.

  If branch coverage was measured (see
  [covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
  the missed branches of each file or function are also listed, as
  `missed branches 12 FALSE, 30 b`: the line of the `if` or
  [`switch()`](https://rdrr.io/r/base/switch.html) and the label of the
  branch that was not taken. Only `if` and
  [`switch()`](https://rdrr.io/r/base/switch.html) calls that were
  evaluated are listed; the others are covered by the missed lines.

- ...:

  additional arguments ignored

## Value

The coverage object (invisibly).

## Branches

If branch coverage was measured (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
the percentage of branches taken is also shown after the overall
coverage, e.g. `Coverage: 87.40% (branches 72.00%)`.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) x + 1; g <- function(x) x - 1; h <- function(x) 0",
  "f(1)"
)
print(cov, group = "functions", n = 2)
#> Coverage: 0.00%
#> g: 0.00%
#> h: 0.00%
#> ... and 1 more function; use `print(x, n = Inf)` to show all

cov <- code_coverage(
  "f <- function(x) {\n  if (x) {\n    1\n\n    # no\n    2\n  }\n}",
  "f(FALSE)"
)
print(cov, missing = TRUE)
#> Coverage: 33.33%
#> /tmp/Rtmp9JQJkZ/source.R1a6037221481: 33.33%  missed 3-6
```
