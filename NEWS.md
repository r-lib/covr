# covr (development version)

* `to_cobertura()` now only lists the lines of a method from the file it is
  defined in. Previously methods sharing a name across files, such as the
  `initialize()` methods of R6 classes, listed each other's lines, so Codecov
  showed line numbers past the end of the file and a different coverage than
  `print()` (#629).

* Compiled code coverage now reads gcov's structured JSON output
  (`gcov --json-format`) when gcov supports it (gcc >= 9), instead of parsing
  its text output with regular expressions. covr still parses the text output
  of llvm-cov, the gcov on macOS, and older gcc, and falls back to it for any
  file whose JSON output is missing or can't be read (#609).

  - Lines of C++ templates instantiated more than once in a file are no
    longer counted twice, which also stopped
    `options(covr.gcov_partial = "uncovered")` from working on them.
  - Lines only reached by C++ exceptions, such as a `catch` block that never
    ran, now count as not covered instead of being left out of the coverage.

* S4 methods are now named after their generic and signature, as in their Rd
  aliases, e.g. `show,MyClass-method`, so `print(x, group = "functions")`,
  `tally_coverage(by = "function")` and the other outputs show which generic
  each method belongs to. Previously they were named only by their signature,
  e.g. `numeric#character` (#417). `function_exclusions` patterns that matched
  the old names need to be updated.

* Error and warning messages are shorter and follow the tidyverse style guide,
  starting with a short statement of the problem followed by bulleted details,
  e.g. for unpaired `# nocov start` / `# nocov end` lines.

* `package_coverage()` no longer crashes R when a package stores data read
  with arrow in an environment of its namespace, e.g. in a fastmap. The
  coverage saved by each R process included the contents of the package's
  environments, which are no longer saved, so it is also smaller (#602).
* `package_coverage()` gains a `show_code_output` argument. If `TRUE`, the
  output of `code` is shown on the console while it runs, e.g. to follow it in
  the logs of a CI job, rather than only being shown when `code` fails
  (@gergness, #558).

* `file_report()` now highlights the syntax of the source code, which failed
  with JavaScript errors because the report didn't include jQuery.

* `report()` and `file_report()` use a dark theme when the browser prefers
  one, and have a button to switch between the light and dark themes, which
  the browser remembers for other reports (#563).

* `file_coverage()` gains a `runner` argument to choose how test files are
  run. `runner = testthat::test_file` runs them with testthat's test runner,
  so `expect_snapshot()` and other features that need it work (#501).

* `package_coverage()` now works in renv projects when the package imports
  renv, or a package that embeds it such as vetiver. covr passed all of its
  library paths to the R processes running the tests as site libraries, which
  renv removes from the library paths when it is loaded, so covr, the package
  and its dependencies could no longer be found (#560).
* `report()`, `file_report()` and the coverage percentages printed in the
  console can use other colors for covered and missed code, set with the new
  `covr.report_colors` option, e.g.
  `options(covr.report_colors = c(covered = "#0072B2", missed = "#E69F00"))`
  for blue and orange, which are easier to tell apart with color vision
  deficiency than the default green and red. An optional `partial` element
  sets the color for 75% to 90% coverage. The coverage bars in `report()` now
  use the same thresholds as the console, so files with exactly 75% or 90%
  coverage get the higher color (#529).
* `codecov()` now uploads with Codecov's current upload protocol, a request to
  `https://ingest.codecov.io` for an upload followed by sending the coverage to
  the location it returns, instead of the legacy `/upload/v2` endpoint, which
  Codecov has deprecated and which doesn't support organization-level upload
  tokens (#568, #464). The repository and git service come from the CI service
  or the `origin` remote, and `base_url` is now the upload API, so
  `"https://codecov.io"` is replaced by it. Without a token, pull requests from
  forks on GitHub Actions are uploaded from an unprotected branch
  (`owner:branch`), like `codecov/codecov-action` does, and on GitHub Actions
  pull requests use the head commit of the pull request. `codecov()` now
  returns the response of Codecov, which includes the `url` of the upload, and
  errors with class `covr_codecov_error` or, for HTTP 429 and 5xx, warns with
  class `covr_codecov_warning`, if either request fails.
* `c()` now combines coverage objects, e.g. from runs of tests in different
  directories. The counts of traces in several objects are added, and recorded
  tests are combined as well (#439).

* When gcov fails, the error from `package_coverage()` now includes gcov's
  output, e.g. the `.gcno` version mismatch reported when the package was
  compiled with a different version of gcc than the gcov used (#537).

* `package_coverage()` no longer discards the coverage measured so far, or
  fails with "'from' must be a finite number", when `code` loads the package
  again with `pkgload::load_all()`, e.g. via `devtools::test()` (#641).

* Line coverage is now computed the same way everywhere, so `print()`,
  `percent_coverage()`, `tally_coverage()`, `report()`, `codecov()`,
  `coveralls()`, `to_cobertura()`, `to_sonarqube()` and `to_lcov()` agree. A
  line only counts as covered if all its expressions ran, e.g. `if (x) a else
  b` on one line where `a` never ran is now uncovered in `report()`, `codecov()`
  and `coveralls()`. Lines shared by several functions, such as
  `f <- function() 1; g <- function() 2`, are counted once, and `print()` and
  `percent_coverage()` no longer count lines with only punctuation such as `}`.
  Reported line coverage may decrease slightly (#620).

* `report()` no longer fails with "invalid argument to unary operator" when
  the coverage object has no traces (#540).

* With `options(covr.record_tests = TRUE)`, functions in the recorded test
  calls, such as those of R6 active bindings, no longer keep their environment.
  Saving the coverage of tests that used an active binding of an R6 object
  holding data read with arrow crashed R (#573).

* Expressions in `if` and `switch` branches written without braces now get
  their own counters when the conditional is the body of a function or is
  nested in another call, such as `x <- if (a) b else c` or
  `function(x) if (x) 1 else 2`, like they already did when the conditional is
  a statement in braces. Previously the whole expression shared one counter, so
  a branch that never ran was reported as covered. This changes reported
  coverage: code with such branches may now have lower coverage percentages,
  e.g. `f <- function(x) if (x) 1 else 2` tested only with `f(TRUE)` drops from
  100% to 0% line coverage. This is more complete expression coverage, not
  branch coverage (#279).

* `print.coverage()` gains an `n` argument to limit the number of files or
  functions printed, showing the least covered first (#215).

* The error for unpaired `# nocov start` and `# nocov end` comments now gives
  the name of the file along with the line numbers of the comments (#409).

* `coveralls()` now submits the git commit, branch and remote when
  `service_name = "github-actions"` and a `repo_token` is given, so the
  Coveralls badge is updated for the right branch (#535).

* `to_sonarqube()` now writes file paths relative to the package root (e.g.
  `R/foo.R`) instead of prefixing them with the package name, so the report
  works when the package is the root of the SonarQube project. Use the new
  `path_prefix` argument if the package is in a subdirectory of the project,
  e.g. `path_prefix = "mypkg"` restores the previous paths (#636).

* `package_coverage()` now accepts `outDir` in `...` to save the test and
  example output to a directory of your choice, instead of failing with
  "formal argument "outDir" matched by multiple actual arguments" (#518).

* `package_coverage(allow_failures = TRUE)` now also keeps `install_path` when
  failures are reported as warnings, so the output files they refer to can be
  inspected (#554).

* `file_coverage()`, `code_coverage()`, `environment_coverage()`,
  `function_coverage()` and `with_coverage()` now include code run in
  processes forked by parallel's `mclapply()`, `mcparallel()` and related
  functions, as `package_coverage()` already did. Set
  `options(covr.fix_parallel_mcexit = FALSE)` to turn this off (#410).

* `package_coverage()` now also excludes the `inst/include/<pkg>_RcppExports.h`
  header that Rcpp generates for `// [[Rcpp::interfaces(cpp)]]`, like the other
  files generated by Rcpp and cpp11. These generated files are now also
  excluded with `relative_path = FALSE` or a custom `relative_path` (#531).

* `package_coverage()` now warns when an R process started by the tests, such
  as a Shiny app, callr session or future worker, loaded the package but did
  not save its coverage because it was killed or was still running when the
  tests finished. That coverage used to be silently missing, so the results
  could vary from run to run (#438).

* Lines excluded with `# nocov` are no longer reported as uncovered when they
  are part of a larger expression that is not entirely excluded, such as the
  first and last lines of a function defined inside another function (#594).

* `codecov()` now throws an error if the upload to codecov.io fails, so CI
  jobs that upload coverage fail instead of silently succeeding. Rate limits
  (HTTP 429) and Codecov outages (HTTP 5xx) give a warning instead, so they
  don't fail CI (#565).

* New `to_lcov()` writes coverage as an LCOV tracefile (`lcov.info`), for
  `genhtml` and other tools that read the LCOV format (#442, thanks to
  @MichaelChirico for the initial implementation in #637).

* New `to_lcov()` writes coverage as an LCOV tracefile (`lcov.info`), for
  `genhtml` and other tools that read the LCOV format (#442, thanks to
  @MichaelChirico for the initial implementation in #637).

* `package_coverage()` no longer reports 0% coverage for packages whose last
  file in `R/` is empty (#522).

* New `coverage_to_markdown()` formats coverage as a markdown table, optionally
  compared against a baseline, for GitHub Actions job summaries or pull
  request comments (#519).

* New `coverage_to_markdown()` formats coverage as a markdown table, optionally
  compared against a baseline, for GitHub Actions job summaries or pull
  request comments (#519).

* `options(covr.gcov = "")` once again turns off coverage of compiled code,
  as documented, instead of failing with "gcov not found" (#516).

* Functions nested inside lists and environments, such as
  `fns <- list(a = function(x) x)`, functions defined inside `local()` and
  ggproto methods, can now be traced. This is off by default; enable it for a
  package with `Config/covr/full_traversal: true` in its DESCRIPTION, or with
  `options(covr.full_traversal = TRUE)` (#113).

* New `with_coverage()` measures the coverage of arbitrary code, such as
  `testthat::test_file()`, run against an environment like a package namespace
  loaded with `pkgload::load_all()`. This allows tools such as
  `devtools::test_coverage_active_file()` to use testthat's own runner instead
  of recreating it, so setup files and fixtures found with
  `testthat::test_path()` work as they do in `testthat::test_file()` (related
  to #543, #551).

* `tally_coverage()` gains `by = "function"`, with one row for each function,
  so `zero_coverage(cov, by = "function")` lists the functions that were
  never run. `percent_coverage()` and `print()` also accept it (#245).

* `report()` now bundles Bootstrap 3.4.1 instead of 3.3.5, which had known
  security vulnerabilities (#639).

* `value()` now works on coverage objects of R code; it previously errored
  for anything but compiled code. The structure of coverage objects is now
  documented in `?coverage`, and `as.data.frame()` on a coverage object in
  `?as.data.frame.coverage` (#564).

* `report()` now keeps the Files / Source tabs at the top of the page while
  scrolling, and returning to the file list restores its scroll position
  (#232).

* Fix "argument is missing, with no default" errors when tracing a `switch()`
  call with fall-through cases (`a = ,`) whose subject is piped in with the
  base pipe (`x |> switch(...)`) (#630).

* Lines of compiled code that gcov reports as only partially executed (e.g.
  `if (x) f();` when `f()` never runs) are no longer dropped from the
  coverage. They count as covered, or as not covered with
  `options(covr.gcov_partial = "uncovered")` (#604). covr now runs gcov with
  `-a` so partial lines are also found with llvm-cov, the gcov on macOS, and
  older versions of gcc (#610).

* `covr_error` conditions (and the `covr_warning`s from `allow_failures`) now
  keep the whole failure output in `$output` and its file in `$file`. The
  message shows the last 50 lines and is bounded by `warning.length`
  measured in characters (it was measured inconsistently in bytes, so
  multibyte output could leave the message empty), and `print()` shows the
  last `n` lines, 50 by default. The number of lines can be set with
  `options(covr.failure_lines)` (#570, #642).

* The RStudio addin now prints a message when it starts calculating coverage,
  so there is feedback before the report opens (#404).

* Fix a warning, and possibly an error under `options(warn = 2)`, when tracing
  a `switch()` call with a trailing comma (#483).

* Trace files are now written atomically, and a failure to save or read one
  is reported as a `covr_error` (a `covr_warning` with `allow_failures = TRUE`)
  naming the file, rather than a cryptic `readRDS()` error (#509).

* `package_coverage()` now only deletes `install_path` if coverage succeeds,
  so the test output referenced in failure messages can be inspected
  (@hadley, #615).

* Avoid cyclic namespace dependency when running coverage on httr and its
  dependencies, such as R6 (#623).

* `package_coverage()` gains an `allow_failures` argument (default
  `getOption("covr.allow_failures", FALSE)`). When `TRUE`, failing tests,
  vignettes, examples or `code` produce a warning instead of an error and
  coverage is still returned, e.g. so `covr::report()` can be viewed after a
  long test run with a failure (#533).

* Coverage is now reported for S7 property getters, setters, and validators
  with S7 > 0.2.2, which stores class callbacks in a shared class reference
  (@t-kalinowski, #646).

* Fix a generational garbage-collection bug when replacing traced functions in
  place, without permanently retaining their bodies or environments (#640).

* Tracing a package is faster, as parse data now keeps text only for terminal
  tokens (@erkurtharun, #644).

* `merge_coverage()` is much faster for packages with many traces (@erkurtharun, #643).

* With `options(covr.record_tests = TRUE)`, merging coverage now correctly
  renumbers the test indices of traces that are absent from the first
  coverage object (#643).

* Fix compilation of the `TestCompiled` test package on R 4.6 by using public
  `REAL()` and `INTEGER()` accessors instead of the non-API `DATAPTR()`.

* Fix a rare edge case where `count_test` was called before `.current_test` has
  been initialized leading to crash (@maksymiuks, #631).

* Fix rare error in `clean_coverage_tests` where `NA` were being compared
  in `if` condition (@maksymiuks, #631).

* `clean_coverage_tests` now uses `length(x) == 0` instead of `is.null(x)`
  to account for `NULL` values and `integer(0)` at the same time (@maksymiuks, #631).

# covr 3.6.5

## New Features and improvements

* Added support for `klmr/box` modules. This works best with `file_coverage()`. (@radbasa, #491)

* Performance improvement for compiled code with a lot of compilation units (@krlmlr, #611)

* Fix R CMD check NOTE for upcoming R 4.6: non-API calls to SET_BODY, SET_CLOENV, SET_FORMALS (@t-kalinowski, #587)

## Fixes and minor improvements

* Messages are now displayed using cli instead of crayon (@olivroy, #591).

* covr now uses `testthat::with_mocked_bindings()` for its internal testing (@olivroy, #595).

* Fix a bug preventing `package_coverage()` from running tests when `install_path` is set to a relative path (@gergness, #517, #548).

* Fixed a performance regression and an error triggered by a change in R
  4.4.0. (@kyleam, #588)

* Fixed an issue where attempting to generate code coverage on an already-loaded
  package could fail on Windows. (@kevinushey, #574)

* Prevent `covr.record_tests` option from logging duplicate tests when the same
  line of testing code is hit repeatedly, as in a loop. (@dgkf, #528)

* Normalize `install_path` path before creating directory to prevent
  failures when running covr in a subprocess using a path with Windows 
  `\\` path separators. (@maksymiuks, #592)

# covr 3.6.4

* Fix for a failing test on CRAN

# covr 3.6.3

* Updates to internal usage of `is.atomic()` to work with upcoming R release (@mmaechler , #542)

* `package_coverage()` now works correctly with ignore files when it is not run in the package root directory (@mpadge, #538)

# covr 3.6.2

* Fix S3 generic/method signature consistency and skip an R6 test on R-devel,
  for CRAN checks (#534).

# covr 3.6.1

* `to_cobertura()` is now explicit about the doctype of the resulting XML. It also sets a source path if recorded. (@mmyrte, #524)

* The internal generic `merge_coverage()` now correctly registers the S3 methods.

* The internal test for recording large calls no longer assumes R is on the system PATH.

# covr 3.6.0

* Added `covr.record_tests` option. When `TRUE`, this enables the recording of the trace of the tests being executed and adds an itemization of which tests result in the execution of each trace.
  For more details see `?covr.record_tests` (@dgkf, #463, #485, #503)

* `as.data.frame()` now returns an 0 row data frame when there are no functions in a package (#427)

* `codecov()` is now more robust when `coverage` is not the output from `package_coverage()` and `token` is not provided (#456)

* `package_coverage(code = )` now accepts character vectors of length greater than 1 (@bastistician, #481)

* `package_coverage()` now handles packages with install or render time examples (#488)

* `package_coverage()` now sets the environment variable `R_TESTS` to the tests-startup.R file like R CMD check does (#420)

* `report()` now provides a more detailed error message if the `DT` and `htmltools` dependencies are not installed (#500).

* Fix `parse_gcov` bug when package is stored in directory with regex special characters, see #459

* Error/warning thrown for, respectively, missing gcov or empty parsed gcov output (@stephematician, #448)

* Support Google Cloud Build uploading reports to Codecov.io (@MarkEdmondson1234 #469)

* covr is now licensed as MIT (#454)

# covr 3.5.1

* Generated files from [cpp11](https://cpp11.r-lib.org/) are now ignored (#437)

* `codecov()` and `coveralls()` now retry failed requests before raising an error (#428, @jameslamb)

# covr 3.5.0

* `codecov()` now supports GitHub Actions for public repositories without having to specify a token.

* New `to_sonarqube()` function added to support SonarQube generic XML format (@nibant, @Delfic, #413).

# covr 3.4.0

* `codecov()` now supports GitHub Actions.

* New `in_covr()` function added to return true if code is being run by covr (#407).

* `file_coverage()`, `environment_coverage()` and `function_coverage()` now set
  `R_COVR=true`, to be consistent with `package_coverage()` (#407)

# covr 3.3.2

* Fix test failures in the development version of R (4.0.0) (#400)

# covr 3.3.1

* Fix inadvertent regression in return visibility when functions are covered.
  covr versions prior to 3.3.0 surrounded each statement in `{` blocks. covr
  3.3.0 switched to using `({`, but this caused an inadvertent regression, as
  `(` will make the result visible it is the last expression in a function.
  Using `if (TRUE) {` restores the previous behavior. (#391, #392)

# covr 3.3.0

## New Features

* New `azure()` function added to make it easy to use covr on [Azure
  Pipelines](https://azure.microsoft.com/en-us/products/devops/pipelines/)
  (#370)

* Work around issues related to the new curly curly syntax in rlang (#379, #377, rlang#813)

* Compiled code coverage has been improved, in particular C++ templates now
  contain the merged coverage of all template instances, even if the instances
  were defined in separate compilation units. (#390)

## Bugfixes and minor improvements

* `codecov()` now includes support for the flags field (#365)
* `codecov` now looks `codecov.yml` for token if `CODECOV_TOKEN` envvar is not
  set (@MishaCivey #349).
* `per_line()` now does not track lines with only punctuation such as `}` or `{` (#387)
* `tally_coverage()` now includes compiled code, like it did previously (#384)

* Define the necessary coverage flags for C++14, C++17 and C++20 (#369).

* `to_cobertura()` now works with Cobertura coverage-04.dtd (@samssann, #337).

* [R6](https://github.com/r-lib/R6) class generators prefixed with `.` are now
  included in coverage results (@jameslamb, #356).

* `package_coverage()` gains option `pre_clean`, set to `FALSE` to disable
  cleaning of existing objects before running `package_coverage()` (@jpritikin, #375)

# 3.2.1

* Fix for regression when testing coverage of packages using mclapply (#335).

# 3.2.0

## Breaking changes

* Previously deprecated `shine()` has been removed. Instead use `report()`.

## New Features

* `file_report()` added when viewing coverage for a single file (#308).

* `display_name()` is now exported, which can be useful to filter the coverage
  object by filename.

* `environment_coverage()` added, mainly so it can be used for `devtools::test_coverage_file()`.

* `gitlab()` function added to create a coverage report for GitLab using
  GitLab's internal pages (@surmann, #327, #331).

* The (optional) dependency on shiny has been removed. `report()` can now be
  built with only DT and htmltools installed.

## Bugfixes and minor improvements

* Fix for gcc-8 gcov output producing lines with no coverage counts in them (#328)

* `impute_srcref()` now handles `...` and drop through arguments in switch
  statements (#325).

* `tally_coverage()` now avoids an error when there are NA values in the source
  references (#322).

* `covr(clean = TRUE)` now cleans the temporary library as well (#144)

* `package_coverage()` now returns the end of the file if there is a test error (#319)

* `report()` now handles reports in relative paths with subdirectories correctly (#329)

* `report()` reworked to look more like codecov.io and to display the overall
  coverage (#302, #307).

* DT explicitly loaded early in `report()` so that failures will occur fast if
  it is not installed. (#321, @renkun-ken).

# 3.1.0 #

## Breaking changes

* `shine()` has been deprecated in favor of `report()`.

## New Features

* Add support for `.covrignore` files (#238), to exclude files from the coverage.

* Support future versions of R which do not use parse data by default (#309).

* Allow using `trace_calls()` for manually adding functions to package trace
  that are not found automatically (#295, @mb706).

## Bugfixes

* Fix errors when R is not in the `PATH` (#291)

* Fix line computations when relative paths are being used (#242).

* Fix for Coveralls `Build processing error.` (#285) on pro accounts from
  Travis CI (#306, @kiwiroy).

* Keep attributes of function bodies (#311, @gaborcsardi)

# 3.0.1 #
* Add an RStudio Addin for running a coverage report.

* Never use mcexit fix on windows (#223).

* Fix for a performance regression in parsing and reading parse data (#274).

* Fix `switch` support for packages, which was broken due to a bug in
  how parse data is stored in packages.

* Improve behavior of `switch` coverage, it now supports default values and
  fall through properly.

* Add `-p` flag to gcov command to preserve file paths. Fixes a bug where
  gcov output didn't get reported when multiple compiled source files had
  the same name (#271, @patperry)

# 3.0.0 #
* The covr license has been changed to GPL-3.
* Set environment variable `R_COVR=true` when covr is running (#236, #268).
* Made the gather-and-merge-results step at the end of package_coverage() more memory efficient (#226, @HenrikBengtsson).
* Support code coverage with icc (#247, @QinWang).

# 2.2.2 #
* `filter_not_package_files()` now works if a source reference does not have a filename (#254, @hughjonesd).
* Fix test broken with xml2 v1.1.0
* Filter out non-local filenames from results (#237).
* Vignette rewrite / improvements (#229, @CSJCampbell).
* Fix code that returns `structure(NULL, *)` which is deprecated in R 3.4.0 (#260, #261, @renkun-ken).

# 2.2.1 #
* Fix test broken with DT 0.2

# 2.2.0 #
* Fix tests broken with updated htmlwidgets
* Change report tab title based on filename (Chen Liang).
* Add support for cobertura XML output (@wligtenberg).
* Add mcparallel support by patching `mcparallel:::mcexit()`
  automatically for packages using parallel (#195, @kforner).

# 2.1.0 #
* Add support for GitLab CI (#190, @enbrown).
* Update exclusion documentation to include line_exclusions and function
  exclusions (#191).
* Support coverage of R6 methods (#174).
* Explicitly set default packages (including methods) (#183, #180)
* Set R_LIBS and R_LIBS_SITE as well as R_LIBS_USER (#188).
* Automatically exclude RcppExport files (#170).
* Memoised and Vectorized functions now able to be tracked.

# 2.0.1 #
* Support for filtering by function as well as line.
* Now tracks coverage for RC methods
* Rewrote loading and saving to support parallel code and tests including
  `quit()` calls.
* Made passing code to `function_coverage()` and `package_coverage()` _not_ use
  non-standard evaluation.
* `NULL` statements are analyzed for coverage (#156, @krlmlr).
* Finer coverage analysis for brace-less `if`, `while` and `for` statements (#154, @krlmlr).
* Run any combination of coverage types (#104, #133)
* Remove inconsistencies in line counts between shiny app and services (#129)
* Include header files in gcov output (#112)
* Add support for C++11 (#131)
* Always clean gcov files even on failure (#108)
* zero_coverage works with RStudio markers (#119)
* Remove the devtools dependency

# 1.3.0 #
* Set `.libPaths()` in subprocess to match those in calling process (#140, #147).
* Move devtools dependency to suggests, only needed on windows
* move htmltools to suggests

# 1.0.0 #
* Initial Release
