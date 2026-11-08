# Branch coverage

By setting `options(covr.branch_coverage = TRUE)` before measuring
coverage, covr also records which branches of each `if` and
[`switch()`](https://rdrr.io/r/base/switch.html) in R code were taken.
Line and expression coverage are the same as without it. Branch coverage
is experimental: what counts as a branch, and how branches are stored
and reported, may change.

## Details

The option is read when the code is instrumented, so it has no cost when
it is not set. When it is set, every `if` and
[`switch()`](https://rdrr.io/r/base/switch.html) that runs calls a
function of covr, which makes the code slower.

## Branches

- An `if` has two branches, `"TRUE"` and `"FALSE"`. The `"FALSE"` branch
  of an `if` without an `else` is taken when the condition is `FALSE`.
  Nothing is recorded if the condition is `NA` or otherwise signals an
  error.

- A [`switch()`](https://rdrr.io/r/base/switch.html) has a branch for
  each of its arms, labelled with the name of the arm. Arms that fall
  through to the next arm (`switch(x, a = , b = 1)`) share its branch,
  labelled `"a, b"`. An unnamed arm is labelled `"<default>"`, or with
  its position if all arms are unnamed. A
  [`switch()`](https://rdrr.io/r/base/switch.html) without a default arm
  has another branch, `"<no match>"`, taken when no arm matches,
  including a number that selects no arm. A
  [`switch()`](https://rdrr.io/r/base/switch.html) with arms in `...`
  has no branches.

`&&`, `||` and loops have no branches, nor does compiled code.

If the line where an `if` or
[`switch()`](https://rdrr.io/r/base/switch.html) starts is excluded,
e.g. with `# nocov` (see
[exclusions](https://covr.r-lib.org/dev/reference/exclusions.md)), all
its branches are excluded too.

## Results

The branches are in the `branches` attribute of the coverage object, a
list with an element for each `if` and
[`switch()`](https://rdrr.io/r/base/switch.html), named like the
elements of the coverage object (see
[coverage](https://covr.r-lib.org/dev/reference/coverage.md)). Each is a
list with the `srcref` of the `if` or
[`switch()`](https://rdrr.io/r/base/switch.html), its `functions`, the
`labels` of its branches, and `value`, the number of times each branch
was taken. Use `tally_coverage(by = "branch")` for a data frame with one
row for each branch, and `percent_coverage(by = "branch")` for the
percentage of branches taken.

[`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md),
[`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md),
[`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) and
[`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md)
include the branches. Codecov shows a line with branches that weren't
all taken as partly covered, and counts it as not covered in the
coverage percentage, so the percentage on Codecov is lower with branch
coverage. [`report()`](https://covr.r-lib.org/dev/reference/report.md),
[`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
and
[`to_sonarqube()`](https://covr.r-lib.org/dev/reference/to_sonarqube.md)
don't include the branches yet.

## Examples

``` r
withr::with_options(list(covr.branch_coverage = TRUE), {
  cov <- code_coverage(
    "f <- function(x) {\n  if (x > 0) 'positive'\n  'done'\n}",
    "f(1)"
  )
})
tally_coverage(cov, by = "branch")
#>                               filename functions line column branch label value
#> 1 /tmp/Rtmpp7vAB7/source.R185d73d0cb3d         f    2      3      1  TRUE     1
#> 2 /tmp/Rtmpp7vAB7/source.R185d73d0cb3d         f    2      3      2 FALSE     0
percent_coverage(cov, by = "branch")
#> [1] 50
```
