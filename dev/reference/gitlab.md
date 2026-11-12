# Run covr on package and create report for GitLab

Utilize internal GitLab static pages to publish package coverage.
Creates local covr report in a package subdirectory. Uses the
[pages](https://docs.gitlab.com/user/project/pages/) GitLab job to
publish the report.

## Usage

``` r
gitlab(..., coverage = NULL, file = "public/coverage.html", quiet = TRUE)
```

## Arguments

- ...:

  arguments passed to
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- coverage:

  an existing coverage object to submit, if `NULL`,
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  will be called with the arguments from `...`

- file:

  The path of the HTML report, relative to the root directory of the
  package (not the working directory). Directories that don't exist are
  created.

- quiet:

  if `FALSE`, print the output of running the tests (see
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md),
  which is called when `coverage` is `NULL`) and the coverage before
  submission.

## Value

The path of the report, invisibly.
