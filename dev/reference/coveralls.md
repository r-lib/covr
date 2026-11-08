# Run covr on a package and upload the result to coveralls

On GitHub Actions, use the official [Coveralls
action](https://github.com/coverallsapp/github-action) instead of this
function: write the coverage with
[`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md)
and upload `cobertura.xml` with `coverallsapp/github-action@v2`. See the
README for an example workflow. With branch coverage, upload the LCOV
file written by
[`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md) instead,
as the action reads which branches were taken from it.

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
  is used, otherwise ‘travis-ci’ is used. When `repo_token` is set and
  `service_name` is ‘drone’, ‘jenkins’, ‘travis-pro’ or
  ‘github-actions’, information about the current git commit, branch and
  remote is also submitted.

- quiet:

  if `FALSE`, print the coverage before submission.

## Details

With branch coverage (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
each source file sent to Coveralls also has its `branches`: the line,
block, branch and count of each branch, as in
[`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md). A branch
that was never taken has a count of zero.
