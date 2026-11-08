# A coverage report to include in other documents

`report_html()` creates the coverage report shown by
[`report()`](https://covr.r-lib.org/dev/reference/report.md) as HTML
that can be included in a larger document, such as an R Markdown or
Quarto document or a page made with htmltools. Printing it in an R
Markdown or Quarto chunk includes the report in the document; printing
it in the console shows it in the viewer.

## Usage

``` r
report_html(x = package_coverage())
```

## Arguments

- x:

  a coverage dataset, defaults to running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

## Value

An
[`htmltools::tagList()`](https://rstudio.github.io/htmltools/reference/tagList.html),
with the dependencies of the report attached.

## Details

The report takes the width of the element it is in, and its styles and
scripts only apply to the report, so they don't change the rest of the
document. A document can include several reports.

The colors and the dark theme can be changed as described in
[`report()`](https://covr.r-lib.org/dev/reference/report.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# In an R Markdown or Quarto chunk
report_html(package_coverage())

# Save it with other content
htmltools::save_html(
  htmltools::tagList(
    htmltools::h1("Package review"),
    report_html(package_coverage())
  ),
  "review.html"
)
} # }
```
