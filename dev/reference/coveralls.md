# Run covr on a package and upload the result to coveralls

On GitHub Actions, use the official [Coveralls
action](https://github.com/coverallsapp/github-action) instead of this
function: write the coverage with
[`cobertura()`](https://covr.r-lib.org/dev/reference/cobertura.md) and
upload `cobertura.xml` with `coverallsapp/github-action@v2`. See the
README for an example workflow. With branch coverage, upload the LCOV
file written by [`lcov()`](https://covr.r-lib.org/dev/reference/lcov.md)
instead, as the action reads which branches were taken from it.

## Usage

``` r
coveralls(
  ...,
  coverage = NULL,
  repo_token = Sys.getenv("COVERALLS_TOKEN"),
  service_name = NULL,
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

  The secret repo token for your repository, found on your repository's
  page on Coveralls. Without a token (`""` or `NULL`), only the CI
  service and job are submitted, which Coveralls only accepts from
  Travis CI. With a token, information about the git commit, branch and
  remote is also submitted.

- service_name:

  The name of the CI service. If `NULL`, the environment variable
  `CI_NAME` is used if it is set, otherwise the CI service is detected
  from the environment, e.g. ‘github’ on GitHub Actions and ‘travis-ci’
  on Travis CI. Outside a supported CI service it is ‘local’.

- quiet:

  if `FALSE`, print the coverage before submission.

## Details

With branch coverage (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
each source file sent to Coveralls also has its `branches`: the line,
block, branch and count of each branch, as in
[`lcov()`](https://covr.r-lib.org/dev/reference/lcov.md). A branch that
was never taken has a count of zero.

The CI service, job, pull request, branch and commit are detected from
the environment variables of the services
[`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) supports.
Anywhere else, the branch, commit and remote are looked up from the
local git repository. The environment variables `CI_BRANCH` and
`CI_REMOTE` override the detected branch and remote.
