# Package index

## Measure coverage

Run code or tests and record which expressions were evaluated.

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  : Calculate test coverage for a package
- [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
  : Calculate test coverage for sets of files
- [`function_coverage()`](https://covr.r-lib.org/dev/reference/function_coverage.md)
  : Calculate test coverage for a specific function.
- [`code_coverage()`](https://covr.r-lib.org/dev/reference/code_coverage.md)
  : Calculate coverage of code directly
- [`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)
  : Calculate coverage of an environment
- [`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
  : Calculate coverage of arbitrary code run against an environment
- [`shiny_app_coverage()`](https://covr.r-lib.org/dev/reference/shiny_app_coverage.md)
  : Calculate test coverage for a Shiny app
- [`covr`](https://covr.r-lib.org/dev/reference/covr-package.md)
  [`covr-package`](https://covr.r-lib.org/dev/reference/covr-package.md)
  : covr: Test coverage for packages
- [`in_covr()`](https://covr.r-lib.org/dev/reference/in_covr.md) :
  Determine if code is being run in covr

## Inspect and combine results

- [`coverage`](https://covr.r-lib.org/dev/reference/coverage.md) :
  Coverage objects
- [`print(`*`<coverage>`*`)`](https://covr.r-lib.org/dev/reference/print.coverage.md)
  : Print a coverage object
- [`c(`*`<coverage>`*`)`](https://covr.r-lib.org/dev/reference/c.coverage.md)
  : Combine coverage objects
- [`as.data.frame(`*`<coverage>`*`)`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md)
  : Convert a coverage object to a data frame
- [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
  : Provide percent coverage of package
- [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
  : Tally coverage by line, expression, function or branch
- [`tally_tests()`](https://covr.r-lib.org/dev/reference/tally_tests.md)
  : Tally which tests ran each line
- [`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md)
  : Provide locations of zero coverage
- [`value()`](https://covr.r-lib.org/dev/reference/value.md) : Retrieve
  the execution counts from a coverage object
- [`annotate_coverage()`](https://covr.r-lib.org/dev/reference/annotate_coverage.md)
  : Annotate source code with line and branch coverage

## Reports

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) : Display
  covr results using a standalone report
- [`report_html()`](https://covr.r-lib.org/dev/reference/report_html.md)
  : A coverage report to include in other documents
- [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
  [`file_report_html()`](https://covr.r-lib.org/dev/reference/file_report.md)
  : A coverage report for a specific file
- [`coverage_to_markdown()`](https://covr.r-lib.org/dev/reference/coverage_to_markdown.md)
  : Convert a coverage dataset to a markdown table
- [`coverage_to_list()`](https://covr.r-lib.org/dev/reference/coverage_to_list.md)
  : Convert a coverage dataset to a list
- [`colorblind_palette`](https://covr.r-lib.org/dev/reference/colorblind_palette.md)
  : Colors for color vision deficiency

## Export formats

- [`cobertura()`](https://covr.r-lib.org/dev/reference/cobertura.md) :
  Create a Cobertura XML file
- [`lcov()`](https://covr.r-lib.org/dev/reference/lcov.md) : Create an
  LCOV tracefile
- [`sonarqube()`](https://covr.r-lib.org/dev/reference/sonarqube.md) :
  Create a SonarQube Generic XML file
- [`badge()`](https://covr.r-lib.org/dev/reference/badge.md) : Create a
  coverage badge

## CI services

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) : Run
  covr on a package and upload the result to codecov.io
- [`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md) :
  Run covr on a package and upload the result to coveralls
- [`gitlab()`](https://covr.r-lib.org/dev/reference/gitlab.md) : Run
  covr on package and create report for GitLab

## Options and exclusions

- [`exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md) :
  Exclusions
- [`covr.branch_coverage`](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)
  : Branch coverage
- [`covr.record_tests`](https://covr.r-lib.org/dev/reference/covr.record_tests.md)
  : Record Test Traces During Coverage Execution

## Deprecated

- [`to_cobertura()`](https://covr.r-lib.org/dev/reference/covr-deprecated.md)
  [`to_sonarqube()`](https://covr.r-lib.org/dev/reference/covr-deprecated.md)
  : Deprecated functions
