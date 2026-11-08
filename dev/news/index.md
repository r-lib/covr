# Changelog

## covr (development version)

- New
  [`coverage_to_markdown()`](https://covr.r-lib.org/dev/reference/coverage_to_markdown.md)
  formats coverage as a markdown table, optionally compared against a
  baseline, for GitHub Actions job summaries or pull request comments
  ([\#519](https://github.com/r-lib/covr/issues/519)).

- Functions nested inside lists and environments, such as
  `fns <- list(a = function(x) x)`, functions defined inside
  [`local()`](https://rdrr.io/r/base/eval.html) and ggproto methods, can
  now be traced. This is off by default; enable it for a package with
  `Config/covr/full_traversal: true` in its DESCRIPTION, or with
  `options(covr.full_traversal = TRUE)`
  ([\#113](https://github.com/r-lib/covr/issues/113)).

- New
  [`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
  measures the coverage of arbitrary code, such as
  [`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html),
  run against an environment like a package namespace loaded with
  [`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html).
  This allows tools such as `devtools::test_coverage_active_file()` to
  use testthat’s own runner instead of recreating it (related to
  [\#543](https://github.com/r-lib/covr/issues/543)).

- [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
  gains `by = "function"`, with one row for each function, so
  `zero_coverage(cov, by = "function")` lists the functions that were
  never run.
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
  and [`print()`](https://rdrr.io/r/base/print.html) also accept it
  ([\#245](https://github.com/r-lib/covr/issues/245)).

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) now
  bundles Bootstrap 3.4.1 instead of 3.3.5, which had known security
  vulnerabilities ([\#639](https://github.com/r-lib/covr/issues/639)).

- [`value()`](https://covr.r-lib.org/dev/reference/value.md) now works
  on coverage objects of R code; it previously errored for anything but
  compiled code. The structure of coverage objects is now documented in
  [`?coverage`](https://covr.r-lib.org/dev/reference/coverage.md), and
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on a
  coverage object in
  [`?as.data.frame.coverage`](https://covr.r-lib.org/dev/reference/as.data.frame.coverage.md)
  ([\#564](https://github.com/r-lib/covr/issues/564)).

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) now keeps
  the Files / Source tabs at the top of the page while scrolling, and
  returning to the file list restores its scroll position
  ([\#232](https://github.com/r-lib/covr/issues/232)).

- Fix “argument is missing, with no default” errors when tracing a
  [`switch()`](https://rdrr.io/r/base/switch.html) call with
  fall-through cases (`a = ,`) whose subject is piped in with the base
  pipe (`x |> switch(...)`)
  ([\#630](https://github.com/r-lib/covr/issues/630)).

- Lines of compiled code that gcov reports as only partially executed
  (e.g. `if (x) f();` when `f()` never runs) are no longer dropped from
  the coverage. They count as covered, or as not covered with
  `options(covr.gcov_partial = "uncovered")`
  ([\#604](https://github.com/r-lib/covr/issues/604)).

- `covr_error` conditions (and the `covr_warning`s from
  `allow_failures`) now keep the whole failure output in `$output` and
  its file in `$file`. The message shows the last 50 lines and is
  bounded by `warning.length` measured in characters (it was measured
  inconsistently in bytes, so multibyte output could leave the message
  empty), and [`print()`](https://rdrr.io/r/base/print.html) shows the
  last `n` lines, 50 by default. The number of lines can be set with
  `options(covr.failure_lines)`
  ([\#570](https://github.com/r-lib/covr/issues/570),
  [\#642](https://github.com/r-lib/covr/issues/642)).

- The RStudio addin now prints a message when it starts calculating
  coverage, so there is feedback before the report opens
  ([\#404](https://github.com/r-lib/covr/issues/404)).

- Fix a warning, and possibly an error under `options(warn = 2)`, when
  tracing a [`switch()`](https://rdrr.io/r/base/switch.html) call with a
  trailing comma ([\#483](https://github.com/r-lib/covr/issues/483)).

- Trace files are now written atomically, and a failure to save or read
  one is reported as a `covr_error` (a `covr_warning` with
  `allow_failures = TRUE`) naming the file, rather than a cryptic
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html) error
  ([\#509](https://github.com/r-lib/covr/issues/509)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now only deletes `install_path` if coverage succeeds, so the test
  output referenced in failure messages can be inspected
  ([@hadley](https://github.com/hadley),
  [\#615](https://github.com/r-lib/covr/issues/615)).

- Avoid cyclic namespace dependency when running coverage on httr and
  its dependencies, such as R6
  ([\#623](https://github.com/r-lib/covr/issues/623)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  gains an `allow_failures` argument (default
  `getOption("covr.allow_failures", FALSE)`). When `TRUE`, failing
  tests, vignettes, examples or `code` produce a warning instead of an
  error and coverage is still returned, e.g. so
  [`covr::report()`](https://covr.r-lib.org/dev/reference/report.md) can
  be viewed after a long test run with a failure
  ([\#533](https://github.com/r-lib/covr/issues/533)).

- Coverage is now reported for S7 property getters, setters, and
  validators with S7 \> 0.2.2, which stores class callbacks in a shared
  class reference ([@t-kalinowski](https://github.com/t-kalinowski),
  [\#646](https://github.com/r-lib/covr/issues/646)).

- Fix a generational garbage-collection bug when replacing traced
  functions in place, without permanently retaining their bodies or
  environments ([\#640](https://github.com/r-lib/covr/issues/640)).

- Tracing a package is faster, as parse data now keeps text only for
  terminal tokens ([@erkurtharun](https://github.com/erkurtharun),
  [\#644](https://github.com/r-lib/covr/issues/644)).

- `merge_coverage()` is much faster for packages with many traces
  ([@erkurtharun](https://github.com/erkurtharun),
  [\#643](https://github.com/r-lib/covr/issues/643)).

- With `options(covr.record_tests = TRUE)`, merging coverage now
  correctly renumbers the test indices of traces that are absent from
  the first coverage object
  ([\#643](https://github.com/r-lib/covr/issues/643)).

- Fix compilation of the `TestCompiled` test package on R 4.6 by using
  public `REAL()` and `INTEGER()` accessors instead of the non-API
  `DATAPTR()`.

- Fix a rare edge case where `count_test` was called before
  `.current_test` has been initialized leading to crash
  ([@maksymiuks](https://github.com/maksymiuks),
  [\#631](https://github.com/r-lib/covr/issues/631)).

- Fix rare error in `clean_coverage_tests` where `NA` were being
  compared in `if` condition
  ([@maksymiuks](https://github.com/maksymiuks),
  [\#631](https://github.com/r-lib/covr/issues/631)).

- `clean_coverage_tests` now uses `length(x) == 0` instead of
  `is.null(x)` to account for `NULL` values and `integer(0)` at the same
  time ([@maksymiuks](https://github.com/maksymiuks),
  [\#631](https://github.com/r-lib/covr/issues/631)).

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

- Fix S3 generic/method signature consistency and skip an R6 test on
  R-devel, for CRAN checks
  ([\#534](https://github.com/r-lib/covr/issues/534)).

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
