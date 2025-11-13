# Run covr on a package and upload the result to coveralls

Run covr on a package and upload the result to coveralls

## Usage

``` r
coveralls(
  ...,
  coverage = NULL,
  repo_token = Sys.getenv("COVERALLS_TOKEN"),
  service_name = Sys.getenv("CI_NAME", "travis-ci"),
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

- repo_token:

  The secret repo token for your repository, found at the bottom of your
  repository's page on Coveralls. This is useful if your job is running
  on a service Coveralls doesn't support out-of-the-box. If set to NULL,
  it is assumed that the job is running on travis-ci

- service_name:

  the CI service to use, if environment variable ‘CI_NAME’ is set that
  is used, otherwise ‘travis-ci’ is used.

- quiet:

  if `FALSE`, print the coverage before submission.
