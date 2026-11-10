# covr (development version)

This is a major release. It changes how coverage is counted in several places,
which can lower the coverage covr reports for the same tests; see "Changes to
reported coverage" below.

## Changes to reported coverage

* Line coverage is now computed the same way everywhere, so `print()`,
  `percent_coverage()`, `tally_coverage()`, `report()`, `codecov()`,
  `coveralls()`, `to_cobertura()`, `to_sonarqube()` and `to_lcov()` agree. A
  line only counts as covered if all its expressions ran, e.g. `if (x) a else
  b` on one line where `a` never ran is now uncovered in `report()`, `codecov()`
  and `coveralls()`. Lines shared by several functions, such as
  `f <- function() 1; g <- function() 2`, are counted once, and `print()` and
  `percent_coverage()` no longer count lines with only punctuation such as `}`.
  Reported line coverage may decrease slightly (#620).

* Expressions in `if` and `switch` branches written without braces now get
  their own counters when the conditional is the body of a function or is
  nested in another call, such as `x <- if (a) b else c` or
  `function(x) if (x) 1 else 2`, like they already did when the conditional is
  a statement in braces. Previously the whole expression shared one counter, so
  a branch that never ran was reported as covered. This changes reported
  coverage: code with such branches may now have lower coverage percentages,
  e.g. `f <- function(x) if (x) 1 else 2` tested only with `f(TRUE)` drops from
  100% to 0% line coverage. The same applies to `if` and `switch()` without
  braces in the default values of arguments, e.g.
  `function(x = if (y) 1 else 2)`. This is more complete expression coverage,
  not branch coverage (#279, #682).

* Braceless `while` loop bodies are now counted separately from the loop
  condition, like `if` and `for`.

* Lines excluded with `# nocov` are no longer reported as uncovered when they
  are part of a larger expression that is not entirely excluded, such as the
  first and last lines of a function defined inside another function (#594).

* Compiled code coverage counts differently in several cases:

  - Lines of C++ templates instantiated more than once in a file are no
    longer counted twice, which also stopped
    `options(covr.gcov_partial = "uncovered")` from working on them (#609).
  - Lines only reached by C++ exceptions, such as a `catch` block that never
    ran, now count as not covered instead of being left out of the coverage
    (#609).
  - Lines of compiled code that gcov reports as only partially executed (e.g.
    `if (x) f();` when `f()` never runs) are no longer dropped from the
    coverage. They count as covered, or as not covered with
    `options(covr.gcov_partial = "uncovered")` (#604). covr now runs gcov with
    `-a` so partial lines are also found with llvm-cov, the gcov on macOS, and
    older versions of gcc (#610).

## Breaking changes

* covr now requires R 4.0.0 or later.

* S4 methods are now named after their generic and signature, as in their Rd
  aliases, e.g. `show,MyClass-method`, so `print(x, group = "functions")`,
  `tally_coverage(by = "function")` and the other outputs show which generic
  each method belongs to. Previously they were named only by their signature,
  e.g. `numeric#character` (#417). `function_exclusions` patterns that matched
  the old names need to be updated.

* `to_sonarqube()` now writes file paths relative to the package root (e.g.
  `R/foo.R`) instead of prefixing them with the package name, so the report
  works when the package is the root of the SonarQube project. Use the new
  `path_prefix` argument if the package is in a subdirectory of the project,
  e.g. `path_prefix = "mypkg"` restores the previous paths (#636).

* `codecov()` now throws an error if the upload to codecov.io fails, so CI
  jobs that upload coverage fail instead of silently succeeding. The error has
  class `covr_codecov_error`. Rate limits (HTTP 429) and Codecov outages (HTTP
  5xx) give a warning of class `covr_codecov_warning` instead, so they don't
  fail CI (#565).

* `codecov()` uses a new upload protocol, and `base_url` is now the upload API
  rather than `"https://codecov.io"`; see "CI services and output formats"
  (#568).

* `coveralls()` now sets `service_name` to `"local"` rather than `"travis-ci"`
  outside a supported CI service, and the git committer fields are now named
  as Coveralls expects (`committer_name`, `committer_email`) (#535).

* `package_coverage()` no longer accepts the `exclusions` argument, deprecated
  in favor of `line_exclusions`.

* `package_coverage(pre_clean =)` is deprecated and ignored; compiled objects
  in `src/` are always removed before the package is installed.

* `azure()` is deprecated. Use `to_cobertura()`, which it calls, instead.

* covr no longer supports code coverage with Intel's classic `icc` compiler,
  which Intel discontinued in 2024, and the `covr.icov`, `covr.icov_args`,
  `covr.icov_flags` and `covr.icov_prof` options have been removed.

* `codecov()` no longer detects Codeship, Semaphore (classic) and Wercker, which
  have been shut down. Their environment variables are now ignored and the
  commit, branch and repository come from the local git repository.

## Performance

* Code run to measure coverage is faster. Evaluated expressions are counted in
  C rather than in R (about 6 times less overhead per expression), and
  instrumented code no longer checks whether tests are recorded with
  `covr.record_tests` every time an expression runs.

* `package_coverage()` instruments and byte-compiles a source package once,
  after installing it, rather than every time a process loads it. The package
  is installed without byte-compiling it, then its instrumented functions are
  byte-compiled and written back to the installed package, so each process
  that loads it starts faster (e.g. 0.3 s rather than 4.6 s for Luminescence)
  and doesn't compile the functions again as it runs them. Functions that
  `.onLoad()` creates or replaces are instrumented when the package is loaded.
  If instrumenting after installing fails, or the package has functions in
  `R/sysdata.rda`, the package is instrumented when it is loaded, as before.
  Set `options(covr.install_instrument = FALSE)` (or the environment variable
  `COVR_INSTALL_INSTRUMENT=false`) to always do that.
  Functions of the package that are sent to other R processes, e.g. parallel
  workers, are now counted there if the process loads the package.
  workers, are now counted there if the process loads the package. Set
  `options(covr.install_compile = FALSE)` (or the environment variable
  `COVR_INSTALL_COMPILE=false`) to leave compiling the functions to the JIT in
  each process instead (#740).

* `report()`, `report_html()` and `file_report_html()` are much faster for
  large packages, as the source table is built as text rather than an
  htmltools tag per line (e.g. 6 minutes to a few seconds for Luminescence).

* `percent_coverage()`, `tally_coverage()`, `zero_coverage()`, `report()` and
  the exclusions in `package_coverage()` are faster for packages with many
  files, as the package source is now split into files once rather than once
  per file.

* `merge_coverage()` is much faster for packages with many traces
  (@erkurtharun, #643).

* Tracing a package is faster, as parse data now keeps text only for terminal
  tokens (@erkurtharun, #644).

## Branch coverage

* New experimental branch coverage of R code. With
  `options(covr.branch_coverage = TRUE)`, covr also records which branches of
  each `if` (including an `if` without an `else`) and `switch()` were taken,
  in the `branches` attribute of the coverage object. `tally_coverage(by =
  "branch")` and `percent_coverage(by = "branch")` summarize them, and
  `to_lcov()`, `to_cobertura()`, `codecov()` and `coveralls()` include them.
  Line coverage is unchanged, and without the option the code is instrumented
  as before, so there is no cost. See `?covr.branch_coverage` (#279).

## Measuring more code

* `package_coverage()` now measures the coverage of Rust code, such as the
  code of packages using extendr or savvy. It's built with LLVM's source-based
  coverage, which needs the llvm tools of the Rust toolchain
  (`rustup component add llvm-tools`), or for Rust installed by a Linux
  distribution, those of the LLVM version rustc uses (e.g. `llvm-cov-18`).
  Without them covr warns and only skips the Rust code.
  `options(covr.llvm_cov = "")` turns this off (#728).

* `file_coverage()` can now measure the coverage of a package's compiled code
  in the current session, e.g. `file_coverage("src/foo.c", "tests/foo.R")`,
  which is much faster than `package_coverage()` (#605). It loads the package
  with `pkgload::load_all()`, builds an instrumented copy of it in the
  session's temporary directory, and only recompiles the files that changed
  on later runs. `environment_coverage()` and `with_coverage()` also include
  the compiled code of packages loaded with `pkgload::load_all()`, so
  `devtools::test_coverage_active_file()` now works for files in `src/`.

* New `shiny_app_coverage()` measures the coverage of a Shiny app that isn't
  part of a package while its tests run, by default with
  `shinytest2::test_app()`, including the code run by the app in the R
  processes that shinytest2 starts. The new `vignette("shiny")` describes how
  to measure the coverage of Shiny apps, including tests run with shinytest2
  and apps that aren't in a package (#277).

* `package_coverage()` now measures the coverage of installed packages, e.g.
  `package_coverage(system.file(package = "pkg"))`, so the package source isn't
  needed. Previously it silently returned no coverage. The package must be
  installed with `--install-tests` and `--with-keep.source`, and
  `package_coverage()` errors if it wasn't (#638).

* Functions nested inside lists and environments, such as
  `fns <- list(a = function(x) x)`, functions defined inside `local()` and
  ggproto methods, can now be traced. This is off by default; enable it for a
  package with `Config/covr/full_traversal: true` in its DESCRIPTION, or with
  `options(covr.full_traversal = TRUE)` (#113).

* `file_coverage()`, `code_coverage()`, `environment_coverage()`,
  `function_coverage()` and `with_coverage()` now include code run in
  processes forked by parallel's `mclapply()`, `mcparallel()` and related
  functions, as `package_coverage()` already did. Set
  `options(covr.fix_parallel_mcexit = FALSE)` to turn this off (#410).

* Coverage is now reported for S7 property getters, setters, and validators
  with S7 > 0.2.2, which stores class callbacks in a shared class reference
  (@t-kalinowski, #646).

* covr no longer reads active bindings (which could fail, e.g. with
  `makeActiveBinding('x', function() stop('boom'), environment())`) when looking
  for functions to trace in packages, R6 classes, S7 objects and box modules.

## Reports

* New `report_html()` and `file_report_html()` return the coverage reports of
  `report()` and `file_report()` as HTML that can be included in a larger
  document, such as an R Markdown or Quarto document. The reports' styles and
  scripts only apply to the report, and a report no longer uses Bootstrap's
  JavaScript or replaces the document's highlight.js, so a document can include
  several reports without changing the rest of the page. The reports no longer
  need the DT package, jQuery or Bootstrap (so they no longer bundle Bootstrap,
  whose bundled version had known security vulnerabilities, #639), and the list
  of files is now shown sorted with the least covered files first (#316, #709).

* `report()` and `file_report()` use a dark theme when the browser prefers
  one, and have a button to switch between the light and dark themes, which
  the browser remembers for other reports (#563).

* `report()`, `file_report()` and the coverage percentages printed in the
  console can use other colors for covered and missed code, set with the new
  `covr.report_colors` option, e.g.
  `options(covr.report_colors = c(covered = "#0072B2", missed = "#E69F00"))`
  for blue and orange, which are easier to tell apart with color vision
  deficiency than the default green and red. An optional `partial` element
  sets the color for 75% to 90% coverage. The coverage bars in `report()` now
  use the same thresholds as the console, so files with exactly 75% or 90%
  coverage get the higher color (#529).

* `report()` now keeps the Files / Source tabs at the top of the page while
  scrolling, and returning to the file list restores its scroll position
  (#232).

* `file_report()` now highlights the syntax of the source code, which failed
  with JavaScript errors because the report didn't include jQuery.

* The RStudio addin now prints a message when it starts calculating coverage,
  so there is feedback before the report opens (#404).

* `report()` no longer fails with "invalid argument to unary operator" when
  the coverage object has no traces (#540).

## CI services and output formats

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
  returns the response of Codecov, which includes the `url` of the upload.

* `codecov()` outside a git repository now gives its "Can't determine the
  repository" error instead of a git failure, as covr's failed git commands
  could escape its error handlers.

* `coveralls()` now detects the CI service, job and pull request on the
  services that `codecov()` supports, e.g. GitHub Actions, instead of
  assuming Travis CI. With a `repo_token`, it also submits the git commit,
  branch and remote on every service, or from the local git repository
  outside CI, so the Coveralls badge is updated for the right branch (#535).

* New `to_badge()` writes an SVG badge with the percent coverage, so a README
  can show coverage without uploading it to Codecov or Coveralls. The README
  has an example GitHub Actions workflow that publishes the badge (#634).

* New `to_lcov()` writes coverage as an LCOV tracefile (`lcov.info`), for
  `genhtml` and other tools that read the LCOV format (#442, thanks to
  @MichaelChirico for the initial implementation in #637).

* New `coverage_to_markdown()` formats coverage as a markdown table, optionally
  compared against a baseline, for GitHub Actions job summaries or pull
  request comments (#519).

* `to_cobertura()` now only lists the lines of a method from the file it is
  defined in. Previously methods sharing a name across files, such as the
  `initialize()` methods of R6 classes, listed each other's lines, so Codecov
  showed line numbers past the end of the file and a different coverage than
  `print()` (#629).

## Working with coverage results
* `package_coverage()` is faster and uses much less memory when the code
  starts many R processes that load the package. Each process now saves only
  the counts it recorded, which are added to the counters saved when the
  package was instrumented, rather than all its counters and their source
  references (a few KB rather than 1 MB per process for languageserver). The
  traces of the processes are also added up as they are read, rather than all
  read first. Measuring the coverage of languageserver's tests, which start
  about 1,000 processes, took more than 7 GB to merge their traces (#744).

* `tally_coverage()`, and so `percent_coverage()`, `zero_coverage()`,
  `coverage_to_list()` and the reports, are about 4 times faster for large
  coverage objects, and `print()` about 8 times faster (e.g. 0.16 s rather than
  0.7 s, and 0.18 s rather than 1.4 s, for Luminescence). The rows of
  `tally_coverage(by = "line")` are now numbered from 1 (#745).

* New `annotate_coverage()` shows the source of the missed lines, or any other
  lines, as plain text with their execution counts, so coverage can be read
  without the HTML report, e.g. by coding agents. With branch coverage, lines
  with a branch that was never taken are shown and marked too. Its output is
  capped at 200 source lines (`max_lines`, or the `covr.annotate_max_lines`
  option), ending with how many lines were left out.

* `print()` of coverage objects gains a `missing` argument; `missing = TRUE`
  lists the missed lines of each file or function as ranges such as
  `41-48, 112`, and the missed branches if branch coverage was measured. The
  branch coverage percentage is shown when it was measured. At most 10 ranges
  and branches are listed for each file or function, which can be changed with
  the `covr.print_max_ranges` option.

* `c()` now combines coverage objects, e.g. from runs of tests in different
  directories. The counts of traces in several objects are added, and recorded
  tests are combined as well (#439).

* `tally_coverage()` gains `by = "function"`, with one row for each function,
  so `zero_coverage(cov, by = "function")` lists the functions that were
  never run. `percent_coverage()` and `print()` also accept it (#245).

* `print.coverage()` gains an `n` argument to limit the number of files or
  functions printed, showing the least covered first (#215).

* New `tally_tests()` returns a traceability matrix from coverage recorded with
  `options(covr.record_tests = TRUE)`: which tests ran each line of code, with
  the test file, line and `test_that()` description, so you can find the tests
  to rerun after changing some lines (#361).

* `value()` now works on coverage objects of R code; it previously errored
  for anything but compiled code. The structure of coverage objects is now
  documented in `?coverage`, and `as.data.frame()` on a coverage object in
  `?as.data.frame.coverage` (#564).

* `covr_error` conditions (and the `covr_warning`s from `allow_failures`) now
  keep the whole failure output in `$output` and its file in `$file`. The
  message shows the last 50 lines and is bounded by `warning.length`
  measured in characters (it was measured inconsistently in bytes, so
  multibyte output could leave the message empty), and `print()` shows the
  last `n` lines, 50 by default. The number of lines can be set with
  `options(covr.failure_lines)` (#570, #642).

* Error and warning messages are shorter and follow the tidyverse style guide,
  starting with a short statement of the problem followed by bulleted details,
  e.g. for unpaired `# nocov start` / `# nocov end` lines.

* The error for unpaired `# nocov start` and `# nocov end` comments now gives
  the name of the file along with the line numbers of the comments (#409).

## Running coverage

* New `with_coverage()` measures the coverage of arbitrary code, such as
  `testthat::test_file()`, run against an environment like a package namespace
  loaded with `pkgload::load_all()`. This allows tools such as
  `devtools::test_coverage_active_file()` to use testthat's own runner instead
  of recreating it, so setup files and fixtures found with
  `testthat::test_path()` work as they do in `testthat::test_file()` (related
  to #543, #551).

* `file_coverage()` gains a `runner` argument to choose how test files are
  run. `runner = testthat::test_file` runs them with testthat's test runner,
  so `expect_snapshot()` and other features that need it work (#501).

* `package_coverage()` gains an `allow_failures` argument (default
  `getOption("covr.allow_failures", FALSE)`). When `TRUE`, failing tests,
  vignettes, examples or `code` produce a warning instead of an error and
  coverage is still returned, e.g. so `covr::report()` can be viewed after a
  long test run with a failure (#533).

* `package_coverage(allow_failures = TRUE)` now also keeps `install_path` when
  failures are reported as warnings, so the output files they refer to can be
  inspected (#554).

* `package_coverage()` now only deletes `install_path` if coverage succeeds,
  so the test output referenced in failure messages can be inspected
  (@hadley, #615).

* `package_coverage()` gains a `show_code_output` argument. If `TRUE`, the
  output of `code` is shown on the console while it runs, e.g. to follow it in
  the logs of a CI job, rather than only being shown when `code` fails
  (@gergness, #558).

* `package_coverage()` now accepts `outDir` in `...` to save the test and
  example output to a directory of your choice, instead of failing with
  "formal argument "outDir" matched by multiple actual arguments" (#518).

* `package_coverage()` now warns when an R process started by the tests, such
  as a Shiny app, callr session or future worker, loaded the package but did
  not save its coverage because it was killed or was still running when the
  tests finished. That coverage used to be silently missing, so the results
  could vary from run to run (#438).

* `package_coverage()` now works in renv projects when the package imports
  renv, or a package that embeds it such as vetiver. covr passed all of its
  library paths to the R processes running the tests as site libraries, which
  renv removes from the library paths when it is loaded, so covr, the package
  and its dependencies could no longer be found (#560).

* `package_coverage(combine_types = FALSE)` now works when its arguments are
  local variables of the calling function.

* `package_coverage()` no longer discards the coverage measured so far, or
  fails with "'from' must be a finite number", when `code` loads the package
  again with `pkgload::load_all()`, e.g. via `devtools::test()` (#641).

* Trace files are now written atomically, and a failure to save or read one
  is reported as a `covr_error` (a `covr_warning` with `allow_failures = TRUE`)
  naming the file, rather than a cryptic `readRDS()` error (#509).

## Compiled code

* Compiled code coverage now reads gcov's structured JSON output
  (`gcov --json-format`) when gcov supports it (gcc >= 9), instead of parsing
  its text output with regular expressions. covr still parses the text output
  of llvm-cov, the gcov on macOS, and older gcc, and falls back to it for any
  file whose JSON output is missing or can't be read (#609).

* When gcov fails, the error from `package_coverage()` now includes gcov's
  output, e.g. the `.gcno` version mismatch reported when the package was
  compiled with a different version of gcc than the gcov used (#537).

* `options(covr.gcov = "")` once again turns off coverage of compiled code,
  as documented, instead of failing with "gcov not found" (#516).

* `package_coverage()` now also excludes the `inst/include/<pkg>_RcppExports.h`
  header that Rcpp generates for `// [[Rcpp::interfaces(cpp)]]`, like the other
  files generated by Rcpp and cpp11. These generated files are now also
  excluded with `relative_path = FALSE` or a custom `relative_path` (#531).

## Bug fixes

* `package_coverage()` no longer crashes R when a package stores data read
  with arrow in an environment of its namespace, e.g. in a fastmap. The
  coverage saved by each R process included the contents of the package's
  environments, which are no longer saved, so it is also smaller (#602).

* `package_coverage()` no longer reports 0% coverage for packages whose last
  file in `R/` is empty (#522).

* `package_coverage()` no longer reports spurious uncovered lines for braceless
  `if`, `for` and `switch` conditions when some of the R processes that load
  the package run with `options(keep.parse.data = FALSE)`.

* `zero_coverage()` no longer errors in RStudio when rstudioapi isn't
  installed.

* Fix "argument is missing, with no default" errors when tracing a `switch()`
  call with fall-through cases (`a = ,`) whose subject is piped in with the
  base pipe (`x |> switch(...)`) (#630).

* Fix a warning, and possibly an error under `options(warn = 2)`, when tracing
  a `switch()` call with a trailing comma (#483).

* Avoid cyclic namespace dependency when running coverage on httr and its
  dependencies, such as R6 (#623).

* Fix a generational garbage-collection bug when replacing traced functions in
  place, without permanently retaining their bodies or environments (#640).

* Two fixes for `options(covr.record_tests = TRUE)` (#627):

  - Objects used in tests can now be garbage collected. covr kept the
    environment of the last test call, which made tests that check that
    objects are finalized fail, e.g. in websocket.
  - Tests without srcrefs, such as the scripts in `tests/` that don't use
    testthat, are now recorded once and counted when they run again, e.g. in a
    loop, like tests with srcrefs. Each run was recorded as a new test, and
    finding the test got slower with every run, so the coverage of bitops
    never finished.

* With `options(covr.record_tests = TRUE)`, tests that call the package through
  code with source references, e.g. testthat expectations when rlang was
  installed with `R_KEEP_PKG_SOURCE=yes`, are no longer all recorded as a
  single test named after that code.

* With `options(covr.record_tests = TRUE)`, functions in the recorded test
  calls, such as those of R6 active bindings, no longer keep their environment.
  Saving the coverage of tests that used an active binding of an R6 object
  holding data read with arrow crashed R (#573).

* With `options(covr.record_tests = TRUE)`, merging coverage now correctly
  renumbers the test indices of traces that are absent from the first
  coverage object (#643).

* Fixed two rare crashes and an error with `options(covr.record_tests = TRUE)`
  (@maksymiuks, #631).

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
