# Run covr on a package and upload the result to codecov.io

Run covr on a package and upload the result to codecov.io

## Usage

``` r
codecov(
  ...,
  coverage = NULL,
  base_url = "https://codecov.io",
  token = NULL,
  commit = NULL,
  branch = NULL,
  pr = NULL,
  flags = NULL,
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

- base_url:

  Codecov url (change for Enterprise)

- token:

  a codecov upload token, if `NULL` then following external sources will
  be checked in this order:

  1.  the environment variable ‘CODECOV_TOKEN’. If it is empty, then

  2.  package will look at directory of the package for a file
      `codecov.yml`. File must have `codecov` section where field
      `token` is set to a token that will be used.

- commit:

  explicitly set the commit this coverage result object corresponds to.
  Is looked up from the service or locally if it is `NULL`.

- branch:

  explicitly set the branch this coverage result object corresponds to,
  this is looked up from the service or locally if it is `NULL`.

- pr:

  explicitly set the pr this coverage result object corresponds to, this
  is looked up from the service if it is `NULL`.

- flags:

  A flag to use for this coverage upload see
  <https://docs.codecov.com/docs/flags> for details.

- quiet:

  if `FALSE`, print the coverage before submission.

## Examples

``` r
if (FALSE) { # \dontrun{
codecov(path = "test")
} # }
```
