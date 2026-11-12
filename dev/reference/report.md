# Display covr results using a standalone report

`report()` saves the coverage report as a standalone HTML file and opens
it. To include the report in a larger document, such as an R Markdown or
Quarto document, use
[`report_html()`](https://covr.r-lib.org/dev/reference/report_html.md)
instead.

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

## Value

`report()` returns the absolute path of the report file, invisibly.

## Branches

If branch coverage was measured with
`options(covr.branch_coverage = TRUE)` (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
the report also shows the branches of each `if` and
[`switch()`](https://rdrr.io/r/base/switch.html). The title has the
percentage of branches taken after the line coverage, and the list of
files has a "Branches" column with the percentage of the branches of
each file that were taken. In the source, a line with branches has the
number of its branches taken out of the total, e.g. `1/2`; hovering over
it or focusing it shows the label and count of each branch. A line with
a branch that wasn't taken is shown as partly covered, unless its `if`
or [`switch()`](https://rdrr.io/r/base/switch.html) never ran, which
leaves it missed.

## Colors

Covered lines are shown in green and missed lines in red. To use other
colors, set the `covr.report_colors` option to a named character vector
of R colors (anything accepted by
[`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html);
transparency is ignored) with elements `covered`, `missed` and/or
`partial`. The colors are used for the highlighted lines and the
coverage bars in the file list; `partial` is used for the bars of files
with at least 75% but less than 90% coverage, which otherwise follow
`covered`, and for the partly covered lines of reports with branches,
which are otherwise yellow.

[colorblind_palette](https://covr.r-lib.org/dev/reference/colorblind_palette.md)
has colors that are easier to tell apart with color vision deficiency:

    options(covr.report_colors = covr::colorblind_palette)

## Dark mode

The report uses a dark theme if the browser or operating system is set
to prefer one. The moon (or sun) button at the top right switches
between the light and dark themes; the browser remembers the choice for
other reports until it is switched back.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- package_coverage()
report(x)

# Colors that are distinguishable with most kinds of color blindness
old <- options(covr.report_colors = colorblind_palette)
report(x)
options(old)
} # }
```
