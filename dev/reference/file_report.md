# A coverage report for a specific file

`file_report()` saves the coverage of one file as a standalone HTML file
and opens it. `file_report_html()` creates the same report as HTML that
can be included in a larger document, like
[`report_html()`](https://covr.r-lib.org/dev/reference/report_html.md).

## Usage

``` r
file_report(
  x = package_coverage(),
  file = NULL,
  out_file = file.path(tempdir(), paste0(get_package_name(x), "-file-report.html")),
  browse = interactive()
)

file_report_html(x = package_coverage(), file = NULL)
```

## Arguments

- x:

  a coverage dataset, defaults to running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).

- file:

  The file to report on, if `NULL`, use the first file in the coverage
  output.

- out_file:

  The output file

- browse:

  whether to open a browser to view the report.

## Value

`file_report()` returns the absolute path of the report file, invisibly.

`file_report_html()` returns an
[`htmltools::tagList()`](https://rstudio.github.io/htmltools/reference/tagList.html),
with the dependencies of the report attached.

## Details

With branch coverage, the report shows the branches of the file as
described in the "Branches" section of
[`report()`](https://covr.r-lib.org/dev/reference/report.md).
