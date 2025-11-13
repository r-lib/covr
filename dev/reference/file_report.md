# A coverage report for a specific file

A coverage report for a specific file

## Usage

``` r
file_report(
  x = package_coverage(),
  file = NULL,
  out_file = file.path(tempdir(), paste0(get_package_name(x), "-file-report.html")),
  browse = interactive()
)
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
