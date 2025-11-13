# Run covr on a package and output the result so it is available on Azure Pipelines

Run covr on a package and output the result so it is available on Azure
Pipelines

## Usage

``` r
azure(
  ...,
  coverage = package_coverage(..., quiet = quiet),
  filename = "coverage.xml",
  quiet = TRUE
)
```

## Arguments

- ...:

  arguments passed to
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- coverage:

  an existing coverage object to submit, if `NULL`,
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  will be called with the arguments from `...`

- filename:

  the name of the Cobertura XML file

- quiet:

  if `FALSE`, print the coverage before submission.
