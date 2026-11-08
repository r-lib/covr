# Display covr results using a standalone report

Display covr results using a standalone report

## Usage

``` r
report(
  x = package_coverage(),
  file = file.path(tempdir(), paste0(get_package_name(x), "-report.html")),
  browse = interactive()
)
```

## Arguments

- x:

  a coverage dataset, defaults to running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

- file:

  The report filename.

- browse:

  whether to open a browser to view the report.

## Colors

Covered lines are shown in green and missed lines in red. To use other
colors, e.g. a pair that is easier to tell apart with color vision
deficiency, set the `covr.report_colors` option to a named character
vector of R colors (anything accepted by
[`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html);
transparency is ignored) with elements `covered`, `missed` and/or
`partial`. The colors are used for the highlighted lines and the
coverage bars in the file list; `partial` is used for the bars of files
with at least 75% but less than 90% coverage, which otherwise follow
`covered`.

    options(covr.report_colors = c(covered = "#0072B2", missed = "#E69F00"))

## Examples

``` r
if (FALSE) { # \dontrun{
x <- package_coverage()
report(x)

# Blue and orange, which are distinguishable with most kinds of color
# blindness
old <- options(
  covr.report_colors = c(covered = "#0072B2", missed = "#E69F00")
)
report(x)
options(old)
} # }
```
