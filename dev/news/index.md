# Changelog

## covr (development version)

- New
  [`report_html()`](https://covr.r-lib.org/dev/reference/report_html.md)
  and
  [`file_report_html()`](https://covr.r-lib.org/dev/reference/file_report.md)
  return the coverage reports of
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) and
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
  as HTML that can be included in a larger document, such as an R
  Markdown or Quarto document. The reports’ styles and scripts only
  apply to the report, so a document can include several reports without
  changing the rest of the page. The reports no longer need the DT
  package, jQuery or Bootstrap, and the list of files is now shown
  sorted with the least covered files first
  ([\#316](https://github.com/r-lib/covr/issues/316),
  [\#709](https://github.com/r-lib/covr/issues/709)).

- covr now requires R 4.0.0 or later.

- New [`to_badge()`](https://covr.r-lib.org/dev/reference/to_badge.md)
  writes an SVG badge with the percent coverage, so a README can show
  coverage without uploading it to Codecov or Coveralls. The README has
  an example GitHub Actions workflow that publishes the badge
  ([\#634](https://github.com/r-lib/covr/issues/634)).

- New
  [`vignette("shiny")`](https://covr.r-lib.org/dev/articles/shiny.md)
  describes how to measure the coverage of Shiny apps, including tests
  run with shinytest2 and apps that aren’t in a package
  ([\#277](https://github.com/r-lib/covr/issues/277)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now measures the coverage of installed packages, e.g.
  `package_coverage(system.file(package = "pkg"))`, so the package
  source isn’t needed. Previously it silently returned no coverage. The
  package must be installed with `--install-tests` and
  `--with-keep.source`, and
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  errors if it wasn’t
  ([\#638](https://github.com/r-lib/covr/issues/638)).

- Two fixes for `options(covr.record_tests = TRUE)`
  ([\#627](https://github.com/r-lib/covr/issues/627)):

  - Objects used in tests can now be garbage collected. covr kept the
    environment of the last test call, which made tests that check that
    objects are finalized fail, e.g. in websocket.
  - Tests without srcrefs, such as the scripts in `tests/` that don’t
    use testthat, are now recorded once and counted when they run again,
    e.g. in a loop, like tests with srcrefs. Each run was recorded as a
    new test, and finding the test got slower with every run, so the
    coverage of bitops never finished.

- [`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md)
  now only lists the lines of a method from the file it is defined in.
  Previously methods sharing a name across files, such as the
  [`initialize()`](https://rdrr.io/r/methods/new.html) methods of R6
  classes, listed each other’s lines, so Codecov showed line numbers
  past the end of the file and a different coverage than
  [`print()`](https://rdrr.io/r/base/print.html)
  ([\#629](https://github.com/r-lib/covr/issues/629)).

- Compiled code coverage now reads gcov’s structured JSON output
  (`gcov --json-format`) when gcov supports it (gcc \>= 9), instead of
  parsing its text output with regular expressions. covr still parses
  the text output of llvm-cov, the gcov on macOS, and older gcc, and
  falls back to it for any file whose JSON output is missing or can’t be
  read ([\#609](https://github.com/r-lib/covr/issues/609)).

  - Lines of C++ templates instantiated more than once in a file are no
    longer counted twice, which also stopped
    `options(covr.gcov_partial = "uncovered")` from working on them.
  - Lines only reached by C++ exceptions, such as a `catch` block that
    never ran, now count as not covered instead of being left out of the
    coverage.

- S4 methods are now named after their generic and signature, as in
  their Rd aliases, e.g. `show,MyClass-method`, so
  `print(x, group = "functions")`, `tally_coverage(by = "function")` and
  the other outputs show which generic each method belongs to.
  Previously they were named only by their signature,
  e.g. `numeric#character`
  ([\#417](https://github.com/r-lib/covr/issues/417)).
  `function_exclusions` patterns that matched the old names need to be
  updated.

- Error and warning messages are shorter and follow the tidyverse style
  guide, starting with a short statement of the problem followed by
  bulleted details, e.g. for unpaired `# nocov start` / `# nocov end`
  lines.

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  no longer crashes R when a package stores data read with arrow in an
  environment of its namespace, e.g. in a fastmap. The coverage saved by
  each R process included the contents of the package’s environments,
  which are no longer saved, so it is also smaller
  ([\#602](https://github.com/r-lib/covr/issues/602)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  gains a `show_code_output` argument. If `TRUE`, the output of `code`
  is shown on the console while it runs, e.g. to follow it in the logs
  of a CI job, rather than only being shown when `code` fails
  ([@gergness](https://github.com/gergness),
  [\#558](https://github.com/r-lib/covr/issues/558)).

- [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
  now highlights the syntax of the source code, which failed with
  JavaScript errors because the report didn’t include jQuery.

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) and
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
  use a dark theme when the browser prefers one, and have a button to
  switch between the light and dark themes, which the browser remembers
  for other reports ([\#563](https://github.com/r-lib/covr/issues/563)).

- [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
  gains a `runner` argument to choose how test files are run.
  `runner = testthat::test_file` runs them with testthat’s test runner,
  so
  [`expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html)
  and other features that need it work
  ([\#501](https://github.com/r-lib/covr/issues/501)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now works in renv projects when the package imports renv, or a package
  that embeds it such as vetiver. covr passed all of its library paths
  to the R processes running the tests as site libraries, which renv
  removes from the library paths when it is loaded, so covr, the package
  and its dependencies could no longer be found
  ([\#560](https://github.com/r-lib/covr/issues/560)).

- [`report()`](https://covr.r-lib.org/dev/reference/report.md),
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
  and the coverage percentages printed in the console can use other
  colors for covered and missed code, set with the new
  `covr.report_colors` option, e.g.
  `options(covr.report_colors = c(covered = "#0072B2", missed = "#E69F00"))`
  for blue and orange, which are easier to tell apart with color vision
  deficiency than the default green and red. An optional `partial`
  element sets the color for 75% to 90% coverage. The coverage bars in
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) now use
  the same thresholds as the console, so files with exactly 75% or 90%
  coverage get the higher color
  ([\#529](https://github.com/r-lib/covr/issues/529)).

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  uploads with Codecov’s current upload protocol, a request to
  `https://ingest.codecov.io` for an upload followed by sending the
  coverage to the location it returns, instead of the legacy
  `/upload/v2` endpoint, which Codecov has deprecated and which doesn’t
  support organization-level upload tokens
  ([\#568](https://github.com/r-lib/covr/issues/568),
  [\#464](https://github.com/r-lib/covr/issues/464)). The repository and
  git service come from the CI service or the `origin` remote, and
  `base_url` is now the upload API, so `"https://codecov.io"` is
  replaced by it. Without a token, pull requests from forks on GitHub
  Actions are uploaded from an unprotected branch (`owner:branch`), like
  `codecov/codecov-action` does, and on GitHub Actions pull requests use
  the head commit of the pull request.
  [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  returns the response of Codecov, which includes the `url` of the
  upload, and errors with class `covr_codecov_error` or, for HTTP 429
  and 5xx, warns with class `covr_codecov_warning`, if either request
  fails.

- [`c()`](https://rdrr.io/r/base/c.html) now combines coverage objects,
  e.g. from runs of tests in different directories. The counts of traces
  in several objects are added, and recorded tests are combined as well
  ([\#439](https://github.com/r-lib/covr/issues/439)).

- When gcov fails, the error from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now includes gcov’s output, e.g. the `.gcno` version mismatch reported
  when the package was compiled with a different version of gcc than the
  gcov used ([\#537](https://github.com/r-lib/covr/issues/537)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  no longer discards the coverage measured so far, or fails with “‘from’
  must be a finite number”, when `code` loads the package again with
  [`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html),
  e.g. via `devtools::test()`
  ([\#641](https://github.com/r-lib/covr/issues/641)).

- Line coverage is now computed the same way everywhere, so
  [`print()`](https://rdrr.io/r/base/print.html),
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md),
  [`report()`](https://covr.r-lib.org/dev/reference/report.md),
  [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md),
  [`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md),
  [`to_cobertura()`](https://covr.r-lib.org/dev/reference/to_cobertura.md),
  [`to_sonarqube()`](https://covr.r-lib.org/dev/reference/to_sonarqube.md)
  and [`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md)
  agree. A line only counts as covered if all its expressions ran,
  e.g. `if (x) a else b` on one line where `a` never ran is now
  uncovered in
  [`report()`](https://covr.r-lib.org/dev/reference/report.md),
  [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) and
  [`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md).
  Lines shared by several functions, such as
  `f <- function() 1; g <- function() 2`, are counted once, and
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
  no longer count lines with only punctuation such as `}`. Reported line
  coverage may decrease slightly
  ([\#620](https://github.com/r-lib/covr/issues/620)).

- [`report()`](https://covr.r-lib.org/dev/reference/report.md) no longer
  fails with “invalid argument to unary operator” when the coverage
  object has no traces
  ([\#540](https://github.com/r-lib/covr/issues/540)).

- With `options(covr.record_tests = TRUE)`, functions in the recorded
  test calls, such as those of R6 active bindings, no longer keep their
  environment. Saving the coverage of tests that used an active binding
  of an R6 object holding data read with arrow crashed R
  ([\#573](https://github.com/r-lib/covr/issues/573)).

- Expressions in `if` and `switch` branches written without braces now
  get their own counters when the conditional is the body of a function
  or is nested in another call, such as `x <- if (a) b else c` or
  `function(x) if (x) 1 else 2`, like they already did when the
  conditional is a statement in braces. Previously the whole expression
  shared one counter, so a branch that never ran was reported as
  covered. This changes reported coverage: code with such branches may
  now have lower coverage percentages,
  e.g. `f <- function(x) if (x) 1 else 2` tested only with `f(TRUE)`
  drops from 100% to 0% line coverage. This is more complete expression
  coverage, not branch coverage
  ([\#279](https://github.com/r-lib/covr/issues/279)).

- [`print.coverage()`](https://covr.r-lib.org/dev/reference/print.coverage.md)
  gains an `n` argument to limit the number of files or functions
  printed, showing the least covered first
  ([\#215](https://github.com/r-lib/covr/issues/215)).

- The error for unpaired `# nocov start` and `# nocov end` comments now
  gives the name of the file along with the line numbers of the comments
  ([\#409](https://github.com/r-lib/covr/issues/409)).

- [`coveralls()`](https://covr.r-lib.org/dev/reference/coveralls.md) now
  submits the git commit, branch and remote when
  `service_name = "github-actions"` and a `repo_token` is given, so the
  Coveralls badge is updated for the right branch
  ([\#535](https://github.com/r-lib/covr/issues/535)).

- [`to_sonarqube()`](https://covr.r-lib.org/dev/reference/to_sonarqube.md)
  now writes file paths relative to the package root (e.g. `R/foo.R`)
  instead of prefixing them with the package name, so the report works
  when the package is the root of the SonarQube project. Use the new
  `path_prefix` argument if the package is in a subdirectory of the
  project, e.g. `path_prefix = "mypkg"` restores the previous paths
  ([\#636](https://github.com/r-lib/covr/issues/636)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now accepts `outDir` in `...` to save the test and example output to a
  directory of your choice, instead of failing with “formal
  argument”outDir” matched by multiple actual arguments”
  ([\#518](https://github.com/r-lib/covr/issues/518)).

- `package_coverage(allow_failures = TRUE)` now also keeps
  `install_path` when failures are reported as warnings, so the output
  files they refer to can be inspected
  ([\#554](https://github.com/r-lib/covr/issues/554)).

- [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md),
  [`code_coverage()`](https://covr.r-lib.org/dev/reference/code_coverage.md),
  [`environment_coverage()`](https://covr.r-lib.org/dev/reference/environment_coverage.md),
  [`function_coverage()`](https://covr.r-lib.org/dev/reference/function_coverage.md)
  and
  [`with_coverage()`](https://covr.r-lib.org/dev/reference/with_coverage.md)
  now include code run in processes forked by parallel’s `mclapply()`,
  `mcparallel()` and related functions, as
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  already did. Set `options(covr.fix_parallel_mcexit = FALSE)` to turn
  this off ([\#410](https://github.com/r-lib/covr/issues/410)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now also excludes the `inst/include/<pkg>_RcppExports.h` header that
  Rcpp generates for `// [[Rcpp::interfaces(cpp)]]`, like the other
  files generated by Rcpp and cpp11. These generated files are now also
  excluded with `relative_path = FALSE` or a custom `relative_path`
  ([\#531](https://github.com/r-lib/covr/issues/531)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  now warns when an R process started by the tests, such as a Shiny app,
  callr session or future worker, loaded the package but did not save
  its coverage because it was killed or was still running when the tests
  finished. That coverage used to be silently missing, so the results
  could vary from run to run
  ([\#438](https://github.com/r-lib/covr/issues/438)).

- Lines excluded with `# nocov` are no longer reported as uncovered when
  they are part of a larger expression that is not entirely excluded,
  such as the first and last lines of a function defined inside another
  function ([\#594](https://github.com/r-lib/covr/issues/594)).

- [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md) now
  throws an error if the upload to codecov.io fails, so CI jobs that
  upload coverage fail instead of silently succeeding. Rate limits
  (HTTP 429) and Codecov outages (HTTP 5xx) give a warning instead, so
  they don’t fail CI
  ([\#565](https://github.com/r-lib/covr/issues/565)).

- New [`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md)
  writes coverage as an LCOV tracefile (`lcov.info`), for `genhtml` and
  other tools that read the LCOV format
  ([\#442](https://github.com/r-lib/covr/issues/442), thanks to
  [@MichaelChirico](https://github.com/MichaelChirico) for the initial
  implementation in [\#637](https://github.com/r-lib/covr/issues/637)).

- New [`to_lcov()`](https://covr.r-lib.org/dev/reference/to_lcov.md)
  writes coverage as an LCOV tracefile (`lcov.info`), for `genhtml` and
  other tools that read the LCOV format
  ([\#442](https://github.com/r-lib/covr/issues/442), thanks to
  [@MichaelChirico](https://github.com/MichaelChirico) for the initial
  implementation in [\#637](https://github.com/r-lib/covr/issues/637)).

- [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  no longer reports 0% coverage for packages whose last file in `R/` is
  empty ([\#522](https://github.com/r-lib/covr/issues/522)).

- New
  [`coverage_to_markdown()`](https://covr.r-lib.org/dev/reference/coverage_to_markdown.md)
  formats coverage as a markdown table, optionally compared against a
  baseline, for GitHub Actions job summaries or pull request comments
  ([\#519](https://github.com/r-lib/covr/issues/519)).

- New
  [`coverage_to_markdown()`](https://covr.r-lib.org/dev/reference/coverage_to_markdown.md)
  formats coverage as a markdown table, optionally compared against a
  baseline, for GitHub Actions job summaries or pull request comments
  ([\#519](https://github.com/r-lib/covr/issues/519)).

- `options(covr.gcov = "")` once again turns off coverage of compiled
  code, as documented, instead of failing with “gcov not found”
  ([\#516](https://github.com/r-lib/covr/issues/516)).

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
  use testthat’s own runner instead of recreating it, so setup files and
  fixtures found with
  [`testthat::test_path()`](https://testthat.r-lib.org/reference/test_path.html)
  work as they do in
  [`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
  (related to [\#543](https://github.com/r-lib/covr/issues/543),
  [\#551](https://github.com/r-lib/covr/issues/551)).

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
  ([\#604](https://github.com/r-lib/covr/issues/604)). covr now runs
  gcov with `-a` so partial lines are also found with llvm-cov, the gcov
  on macOS, and older versions of gcc
  ([\#610](https://github.com/r-lib/covr/issues/610)).

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
