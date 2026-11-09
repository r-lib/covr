# covr: Test coverage for packages

covr tracks and reports code coverage for your package and (optionally)
upload the results to a coverage service like 'Codecov'
<https://about.codecov.io> or 'Coveralls' <https://coveralls.io>. Code
coverage is a measure of the amount of code being exercised by a set of
tests. It is an indirect measure of test quality and completeness. This
package is compatible with any testing methodology or framework and
tracks coverage of both R code and compiled C/C++/FORTRAN code.

## Details

A coverage report can be used to inspect coverage for each line in your
package. Using
[`report()`](https://covr.r-lib.org/dev/reference/report.md) requires
the additional dependency `htmltools`.

    # If run with no arguments `report()` implicitly calls `package_coverage()`
    report()

## Package options

`covr` uses the following
[`options()`](https://rdrr.io/r/base/options.html) to configure
behaviour:

- `covr.branch_coverage`: If `TRUE` (default `FALSE`), also record which
  branches of each `if` and
  [`switch()`](https://rdrr.io/r/base/switch.html) in R code were taken.
  This is experimental. It must be set before the code is instrumented,
  e.g. before calling
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).
  For more details, see
  [`?covr.branch_coverage`](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md).

- `covr.covrignore`: A filename to use as an ignore file, listing
  glob-style wildcarded paths of files to ignore for coverage
  calculations. Defaults to the value of environment variable
  `COVR_COVRIGNORE`, or `".covrignore"` if the neither the option nor
  the environment variable are set.

- `covr.exclude_end`: Used along with `covr.exclude_start`, an optional
  regular expression which ends a line-exclusion region. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.exclude_pattern`: An optional line-exclusion pattern. Lines
  which match the pattern will be excluded from coverage. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.exclude_start`: Used along with `covr.exclude_end`, an optional
  regular expression which starts a line-exclusion region. For more
  details, see
  [`?exclusions`](https://covr.r-lib.org/dev/reference/exclusions.md).

- `covr.filter_non_package`: If `TRUE` (the default behavior), coverage
  of files outside the target package are filtered from coverage output.

- `covr.failure_lines`: The number of trailing lines of test output
  shown in the message and
  [`print()`](https://rdrr.io/r/base/print.html) method of a
  `covr_error` when tests, vignettes, examples or `code` fail (default
  `50`). The full output is always available in the condition's
  `$output` field.

- `covr.fix_parallel_mcexit`: Whether to include code run in processes
  forked by parallel's `mclapply()`, `mcparallel()` and related
  functions, by patching `parallel:::mcexit`. By default
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  does this if the package uses parallel, and the functions that measure
  coverage in the current session, such as
  [`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md),
  always do. The environment variable `COVR_FIX_PARALLEL_MCEXIT` takes
  precedence over this option. Not supported on Windows.

- `covr.flags`:

- `covr.gcov`: Path to the gcov executable. Defaults to the gcov found
  on your `PATH`, or `NA` if there is none. If the appropriate gcov
  version is not on your path you can use this option to set the
  appropriate location. If set to `""` it will turn off coverage of
  compiled code. If `NA`, covr throws an error if any compiled coverage
  files (`.gcno`) exist.

- `covr.gcov_additional_paths`:

- `covr.gcov_args`:

- `covr.gcov_partial`: How to count compiled code lines that gcov
  reports as only partially executed (e.g. `if (x) f();` when `f()`
  never runs). `"covered"` (the default) counts them as covered,
  `"uncovered"` counts them as not covered, for requiring every part of
  a line to run. This works with both gcc's gcov and llvm-cov (the gcov
  on macOS). llvm-cov can't tell apart code that only runs when a C++
  exception is thrown, so lines that create objects with destructors may
  also count as partially executed.

- `covr.llvm_cov`: Path to the `llvm-cov` used to read the coverage of
  Rust code. Defaults to the one of the Rust toolchain, installed with
  `rustup component add llvm-tools`, or for Rust installed without
  rustup (e.g. with `apt-get install cargo rustc`), to the one on the
  `PATH` with the same LLVM version as rustc, e.g. `llvm-cov-18`. If set
  to `""` the Rust code isn't instrumented, which turns off its
  coverage.

- `covr.llvm_profdata`: Path to the `llvm-profdata` used to merge the
  coverage counts of Rust code. Found like `covr.llvm_cov`.

- `covr.report_colors`: A named character vector with the colors of
  covered and missed lines in
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) and
  [`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md),
  and of the coverage percentages printed in the console, e.g.
  `c(covered = "#0072B2", missed = "#E69F00")` for blue and orange,
  which are easier to tell apart than the default green and red with
  color vision deficiency. Either element can be left out to keep its
  default. An optional `partial` element sets the color of partial
  coverage (at least 75% but less than 90%), which otherwise follows
  `covered`, or is yellow in the console if `covered` isn't set either.
  Transparency is ignored. In terminals with only 8 colors, the console
  uses the closest of those colors.

- `covr.rstudio_source_markers`: A logical value. If `TRUE` (the default
  behavior), source markers are displayed within the RStudio IDE when
  using `zero_coverage`.

- `covr.record_tests`: If `TRUE` (default `NULL`), record a listing of
  top level test expressions and associate tests with `covr` traces
  evaluated during the test's execution. For more details, see
  [`?covr.record_tests`](https://covr.r-lib.org/dev/reference/covr.record_tests.md).

- `covr.full_traversal`: If `TRUE` (default `FALSE`), also trace
  functions nested inside lists and environments, such as
  `fns <- list(a = function(x) x)` or functions defined inside
  [`local()`](https://rdrr.io/r/base/eval.html). This walks every object
  in the package, so it is off by default. For
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  it can also be enabled for a package by adding
  `Config/covr/full_traversal: true` to its DESCRIPTION; the option
  takes precedence when set.

- `covr.showCfunctions`:

## See also

Useful links:

- <https://covr.r-lib.org>

- <https://github.com/r-lib/covr>

- Report bugs at <https://github.com/r-lib/covr/issues>

## Author

**Maintainer**: Jim Hester <james.f.hester@gmail.com>

Authors:

- Jim Hester <james.f.hester@gmail.com>

Other contributors:

- Willem Ligtenberg \[contributor\]

- Kirill Müller \[contributor\]

- Henrik Bengtsson \[contributor\]

- Steve Peak \[contributor\]

- Kirill Sevastyanenko \[contributor\]

- Jon Clayden \[contributor\]

- Robert Flight \[contributor\]

- Eric Brown \[contributor\]

- Brodie Gaslam \[contributor\]

- Will Beasley \[contributor\]

- Robert Krzyzanowski \[contributor\]

- Markus Wamser \[contributor\]

- Karl Forner \[contributor\]

- Gergely Daróczi \[contributor\]

- Jouni Helske \[contributor\]

- Kun Ren \[contributor\]

- Jeroen Ooms \[contributor\]

- Ken Williams \[contributor\]

- Chris Campbell \[contributor\]

- David Hugh-Jones \[contributor\]

- Qin Wang \[contributor\]

- Doug Kelkhoff \[contributor\]

- Ivan Sagalaev (highlight.js library) \[contributor, copyright holder\]
