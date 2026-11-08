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
the additional dependencies `DT` and `htmltools`.

    # If run with no arguments `report()` implicitly calls `package_coverage()`
    report()

## Package options

`covr` uses the following
[`options()`](https://rdrr.io/r/base/options.html) to configure
behaviour:

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

- `covr.fix_parallel_mcexit`:

- `covr.flags`:

- `covr.gcov`: If the appropriate gcov version is not on your path you
  can use this option to set the appropriate location. If set to "" it
  will turn off coverage of compiled code.

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

- `covr.icov`:

- `covr.icov_args`:

- `covr.icov_flags`:

- `covr.icov_prof`:

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

- Mark Otto (Bootstrap library) \[contributor\]

- Jacob Thornton (Bootstrap library) \[contributor\]

- Bootstrap contributors (Bootstrap library) \[contributor\]

- Twitter, Inc (Bootstrap library) \[copyright holder\]
