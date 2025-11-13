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

## Examples

``` r
if (FALSE) { # \dontrun{
x <- package_coverage()
report(x)
} # }
```
