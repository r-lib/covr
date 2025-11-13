# Changelog

## covr (development version)

## covr 3.6.5

CRAN release: 2025-11-09

### New Features and improvements

- Added support for `klmr/box` modules. This works best with
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md).
  ([@radbasa](https://github.com/radbasa),
  [\#491](https://github.com/r-lib/covr/issues/491))

- Performance improvement for compiled code with a lot of compilation
  units ([@krlmlr](https://github.com/krlmlr),
  [\#611](https://github.com/r-lib/covr/issues/611))

- Fix R CMD check NOTE for upcoming R 4.6: non-API calls to SET_BODY,
  SET_CLOENV, SET_FORMALS
  ([@t-kalinowski](https://github.com/t-kalinowski),
  [\#587](https://github.com/r-lib/covr/issues/587))

### Fixes and minor improvements

- Messages are now displayed using cli instead of crayon
  ([@olivroy](https://github.com/olivroy),
  [\#591](https://github.com/r-lib/covr/issues/591)).

- covr now uses
  [`testthat::with_mocked_bindings()`](https://testthat.r-lib.org/reference/local_mocked_bindings.html)
  for its internal testing ([@olivroy](https://github.com/olivroy),
  [\#595](https://github.com/r-lib/covr/issues/595)).

- Fix a bug preventing
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  from running tests when `install_path` is set to a relative path
  ([@gergness](https://github.com/gergness),
  [\#517](https://github.com/r-lib/covr/issues/517),
  [\#548](https://github.com/r-lib/covr/issues/548)).

- Fixed a performance regression and an error triggered by a change in R
  4.4.0. ([@kyleam](https://github.com/kyleam),
  [\#588](https://github.com/r-lib/covr/issues/588))

- Fixed an issue where attempting to generate code coverage on an
  already-loaded package could fail on Windows.
  ([@kevinushey](https://github.com/kevinushey),
  [\#574](https://github.com/r-lib/covr/issues/574))

- Prevent `covr.record_tests` option from logging duplicate tests when
  the same line of testing code is hit repeatedly, as in a loop.
  ([@dgkf](https://github.com/dgkf),
  [\#528](https://github.com/r-lib/covr/issues/528))

- Normalize `install_path` path before creating directory to prevent
  failures when running covr in a subprocess using a path with Windows
  `\\` path separators. ([@maksymiuks](https://github.com/maksymiuks),
  [\#592](https://github.com/r-lib/covr/issues/592))

## covr 3.6.4

CRAN release: 2023-11-09

- Fix for a failing test on CRAN

## covr 3.6.3

CRAN release: 2023-10-10

- Updates to internal usage of
  [`is.atomic()`](https://rdrr.io/r/base/is.recursive.html) to work with
  upcoming R release ([@mmaechler](https://github.com/mmaechler) ,
  [\#542](https://github.com/r-lib/covr/issues/542))

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now works correctly with ignore files when it is not run in the
  package root directory ([@mpadge](https://github.com/mpadge),
  [\#538](https://github.com/r-lib/covr/issues/538))

## covr 3.6.2

CRAN release: 2023-03-25

## covr 3.6.1

CRAN release: 2022-08-26

- [`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md)
  is now explicit about the doctype of the resulting XML. It also sets a
  source path if recorded. ([@mmyrte](https://github.com/mmyrte),
  [\#524](https://github.com/r-lib/covr/issues/524))

- The internal generic `merge_coverage()` now correctly registers the S3
  methods.

- The internal test for recording large calls no longer assumes R is on
  the system PATH.

## covr 3.6.0

CRAN release: 2022-08-24

- Added `covr.record_tests` option. When `TRUE`, this enables the
  recording of the trace of the tests being executed and adds an
  itemization of which tests result in the execution of each trace. For
  more details see
  [`?covr.record_tests`](https://covr.r-lib.org/dev/reference/covr.record_tests.md)
  ([@dgkf](https://github.com/dgkf),
  [\#463](https://github.com/r-lib/covr/issues/463),
  [\#485](https://github.com/r-lib/covr/issues/485),
  [\#503](https://github.com/r-lib/covr/issues/503))

- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) now
  returns an 0 row data frame when there are no functions in a package
  ([\#427](https://github.com/r-lib/covr/issues/427))

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) is now
  more robust when `coverage` is not the output from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  and `token` is not provided
  ([\#456](https://github.com/r-lib/covr/issues/456))

- `package_coverage(code = )` now accepts character vectors of length
  greater than 1 ([@bastistician](https://github.com/bastistician),
  [\#481](https://github.com/r-lib/covr/issues/481))

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now handles packages with install or render time examples
  ([\#488](https://github.com/r-lib/covr/issues/488))

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now sets the environment variable `R_TESTS` to the tests-startup.R
  file like R CMD check does
  ([\#420](https://github.com/r-lib/covr/issues/420))

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) now
  provides a more detailed error message if the `DT` and `htmltools`
  dependencies are not installed
  ([\#500](https://github.com/r-lib/covr/issues/500)).

- Fix `parse_gcov` bug when package is stored in directory with regex
  special characters, see
  [\#459](https://github.com/r-lib/covr/issues/459)

- Error/warning thrown for, respectively, missing gcov or empty parsed
  gcov output ([@stephematician](https://github.com/stephematician),
  [\#448](https://github.com/r-lib/covr/issues/448))

- Support Google Cloud Build uploading reports to Codecov.io
  ([@MarkEdmondson1234](https://github.com/MarkEdmondson1234)
  [\#469](https://github.com/r-lib/covr/issues/469))

- covr is now licensed as MIT
  ([\#454](https://github.com/r-lib/covr/issues/454))

## covr 3.5.1

CRAN release: 2020-09-16

- Generated files from [cpp11](https://cpp11.r-lib.org/) are now ignored
  ([\#437](https://github.com/r-lib/covr/issues/437))

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) and
  [`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md) now
  retry failed requests before raising an error
  ([\#428](https://github.com/r-lib/covr/issues/428),
  [@jameslamb](https://github.com/jameslamb))

## covr 3.5.0

CRAN release: 2020-03-06

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  supports GitHub Actions for public repositories without having to
  specify a token.

- New
  [`to_sonarqube()`](https://covr.r-lib.org/dev/reference/to_sonarqube.md)
  function added to support SonarQube generic XML format
  ([@nibant](https://github.com/nibant),
  [@Delfic](https://github.com/Delfic),
  [\#413](https://github.com/r-lib/covr/issues/413)).

## covr 3.4.0

CRAN release: 2019-11-26

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  supports GitHub Actions.

- New [`in_covr()`](https://covr.r-lib.org/dev/reference/in_covr.md)
  function added to return true if code is being run by covr
  ([\#407](https://github.com/r-lib/covr/issues/407)).

- [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md),
  [`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md)
  and
  [`function_coverage()`](https://covr.r-lib.org/dev/reference/function_coverage.md)
  now set `R_COVR=true`, to be consistent with
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  ([\#407](https://github.com/r-lib/covr/issues/407))

## covr 3.3.2

CRAN release: 2019-10-16

- Fix test failures in the development version of R (4.0.0)
  ([\#400](https://github.com/r-lib/covr/issues/400))

## covr 3.3.1

CRAN release: 2019-08-23

- Fix inadvertent regression in return visibility when functions are
  covered. covr versions prior to 3.3.0 surrounded each statement in `{`
  blocks. covr 3.3.0 switched to using `({`, but this caused an
  inadvertent regression, as `(` will make the result visible it is the
  last expression in a function. Using `if (TRUE) {` restores the
  previous behavior. ([\#391](https://github.com/r-lib/covr/issues/391),
  [\#392](https://github.com/r-lib/covr/issues/392))

## covr 3.3.0

CRAN release: 2019-08-06

### New Features

- New [`azure()`](https://covr.r-lib.org/dev/reference/azure.md)
  function added to make it easy to use covr on [Azure
  Pipelines](https://azure.microsoft.com/en-us/products/devops/pipelines/)
  ([\#370](https://github.com/r-lib/covr/issues/370))

- Work around issues related to the new curly curly syntax in rlang
  ([\#379](https://github.com/r-lib/covr/issues/379),
  [\#377](https://github.com/r-lib/covr/issues/377), rlang#813)

- Compiled code coverage has been improved, in particular C++ templates
  now contain the merged coverage of all template instances, even if the
  instances were defined in separate compilation units.
  ([\#390](https://github.com/r-lib/covr/issues/390))

### Bugfixes and minor improvements

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  includes support for the flags field
  ([\#365](https://github.com/r-lib/covr/issues/365))

- `codecov` now looks `codecov.yml` for token if `CODECOV_TOKEN` envvar
  is not set ([@MishaCivey](https://github.com/MishaCivey)
  [\#349](https://github.com/r-lib/covr/issues/349)).

- `per_line()` now does not track lines with only punctuation such as
  `}` or `{` ([\#387](https://github.com/r-lib/covr/issues/387))

- [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
  now includes compiled code, like it did previously
  ([\#384](https://github.com/r-lib/covr/issues/384))

- Define the necessary coverage flags for C++14, C++17 and C++20
  ([\#369](https://github.com/r-lib/covr/issues/369)).

- [`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md)
  now works with Cobertura coverage-04.dtd
  ([@samssann](https://github.com/samssann),
  [\#337](https://github.com/r-lib/covr/issues/337)).

- [R6](https://github.com/r-lib/R6) class generators prefixed with `.`
  are now included in coverage results
  ([@jameslamb](https://github.com/jameslamb),
  [\#356](https://github.com/r-lib/covr/issues/356)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  gains option `pre_clean`, set to `FALSE` to disable cleaning of
  existing objects before running
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  ([@jpritikin](https://github.com/jpritikin),
  [\#375](https://github.com/r-lib/covr/issues/375))
