# Run covr on a package and upload the result to codecov.io

Uploads coverage to Codecov with the current upload protocol, the one
used by the [Codecov CLI](https://github.com/codecov/codecov-cli) and
the `codecov/codecov-action` GitHub Action. This takes two requests:

## Usage

``` r
codecov(
  ...,
  coverage = NULL,
  base_url = "https://ingest.codecov.io",
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

  the url coverage is uploaded to. The default is Codecov's upload API;
  change it for Codecov Enterprise. The former default
  `"https://codecov.io"` is the website, not the API, so it (and
  `"https://app.codecov.io"`) is replaced by the default.

- token:

  a codecov upload token, if `NULL` then following external sources will
  be checked in this order:

  1.  the environment variable ‘CODECOV_TOKEN’. If it is empty, then

  2.  package will look at directory of the package for a file
      `codecov.yml`. File must have `codecov` section where field
      `token` is set to a token that will be used.

  If there is no token, the upload is sent without one, see the section
  “Tokens”.

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

## Value

The response of Codecov to the request for an upload, invisibly: a list
that includes `url`, the url of the upload on Codecov. If Codecov
rejects either request, `codecov()` throws an error of class
`covr_codecov_error` with the response of Codecov in its message, except
when Codecov is rate limiting requests (HTTP 429) or is unavailable
(HTTP 5xx), when it gives a warning of class `covr_codecov_warning` and
returns `NULL` instead, so CI does not fail because of a transient
Codecov problem.

## Details

1.  `POST <base_url>/upload/<git service>/<owner>::::<repo>/upload-coverage`
    (for a repository in nested groups, `owner/group/repo` is
    `owner:::group::::repo`) tells Codecov about the commit, branch,
    pull request and CI job. The response contains a `url` for the
    upload on Codecov and a pre-signed location to send the coverage
    report to.

2.  `PUT` sends the report, covr's JSON coverage format (processed by
    Codecov as an `R` report), to that location. With branch coverage
    (see
    [covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
    the report uses Codecov's [generic JSON
    format](https://docs.codecov.com/docs/codecov-custom-coverage-format)
    instead, as the `R` format only takes line hits. A line with
    branches then has the number of its branches taken and the number of
    branches, e.g. `"1/2"`, so Codecov shows it as partly covered unless
    all were taken.

If `quiet` is `FALSE`, the url of the upload on Codecov is printed after
a successful upload.

The commit, branch, pull request, job, build URL and repository are
looked up from the environment variables of the CI service, which is one
of Jenkins, Travis, CircleCI, Drone, AppVeyor, GitLab CI, GitHub Actions
or Google Cloud Build. Anywhere else, or for values the service does not
provide, they are looked up from the local git repository in the working
directory. The repository (`owner/repo`) and the git service (`github`,
`gitlab`, `bitbucket`, ...) come from the CI service when it provides
them, otherwise from the `origin` remote of the local git repository,
otherwise the git service is assumed to be `github`.

## Tokens

Codecov authenticates uploads with an upload token, passed in the
`Authorization` header. Both the token of a repository and an
organization (global) upload token, which is shared by all of an
organization's repositories, can be used. The token is looked up as
described for `token`. See
<https://docs.codecov.com/docs/codecov-tokens>.

Without a token, Codecov only accepts uploads for public repositories,
and only for an unprotected branch, which is a branch name with an owner
prefix such as `owner:branch`. Pull requests from forks do not have
access to the token as a CI secret, so on GitHub Actions, when there is
no token, `branch` is `NULL` and the head repository of the pull request
(the `pull_request.head.repo.full_name` of the event in
`GITHUB_EVENT_PATH`) differs from `GITHUB_REPOSITORY`, `codecov()` uses
the label of the head of the pull request, `owner:branch`, as the branch
name, as `codecov/codecov-action` does. Pull requests from the same
repository, other CI services and uploads from other branches use the
plain branch name, so without a token Codecov rejects them unless the
branch is already unprotected.

## Alternative

Instead of uploading from R, write the coverage to a file and upload it
with the `codecov/codecov-action` GitHub Action, or any other Codecov
uploader. [`lcov()`](https://covr.r-lib.org/dev/reference/lcov.md) has
no dependencies and writes `lcov.info`, which the action uploads without
further configuration:

    - name: Test coverage
      run: covr::lcov(covr::package_coverage())
      shell: Rscript {0}

    - uses: codecov/codecov-action@v5
      with:
        token: ${{ secrets.CODECOV_TOKEN }}

[`cobertura()`](https://covr.r-lib.org/dev/reference/cobertura.md)
writes the Cobertura XML format, for which the xml2 package is needed.

## Examples

``` r
if (FALSE) { # \dontrun{
codecov(path = "test")
} # }
```
