# Convert a coverage dataset to a markdown table

Creates a markdown table with the total coverage and the coverage of
each file, suitable for a GitHub Actions job summary or a pull request
comment. If `base` is given, the table also includes the coverage of
`base` and the change from it.

## Usage

``` r
coverage_to_markdown(x = package_coverage(), base = NULL)
```

## Arguments

- x:

  a coverage dataset, defaults to running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

- base:

  an optional coverage dataset to compare against, e.g. the coverage of
  the main branch.

## Value

A character vector of markdown lines, with class `"covr_markdown"`.

## Examples

``` r
cov <- code_coverage(
  "add <- function(x, y) { x + y }",
  "add(1, 2)"
)
coverage_to_markdown(cov)
#> | File | Coverage |
#> | :--- | ---: |
#> | Total | 100.00% |
#> | /tmp/RtmpOeHbfo/source.R19676d9115a | 100.00% |

if (FALSE) { # \dontrun{
# In a GitHub Actions step
md <- coverage_to_markdown(package_coverage())
cat(md, file = Sys.getenv("GITHUB_STEP_SUMMARY"), sep = "\n", append = TRUE)
} # }
```
