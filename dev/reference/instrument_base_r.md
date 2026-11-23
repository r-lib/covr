# Instrument the R code of the base packages of R

Instruments the installed base packages (base, stats, utils, ...) of the
running R, so that the R processes it starts save the counts of the code
they run, in `trace_dir` or in the directory of the environment variable
`COVERAGE_DIR`. The counts are collected by
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md).
This changes the library of the running R: undo it with
[`uninstrument_base_r()`](https://covr.r-lib.org/dev/reference/uninstrument_base_r.md).
Use
[`base_r_compiled_coverage()`](https://covr.r-lib.org/dev/reference/base_r_compiled_coverage.md)
for its C and Fortran code.

## Usage

``` r
instrument_base_r(
  source_dir,
  lib = R.home("library"),
  trace_dir = file.path(dirname(lib), "covr-traces"),
  packages = base_r_packages(lib),
  exclusions = base_r_exclusions(),
  cores = getOption("Ncpus", 1L)
)
```

## Arguments

- source_dir:

  The directory of the source of R, that R was built from.

- lib:

  The library of the base packages of R.

- trace_dir:

  The directory the counts are saved in, if the environment variable
  `COVERAGE_DIR` is not set when a process of R exits.

- packages:

  The packages to instrument, which must include base, whose loader
  counts the code that runs and saves the counts.

- exclusions:

  A named list of the functions not to instrument, by package, e.g.
  `list(stats = "pbinom")`. Use `NULL` to instrument all of them, which
  makes some of R's checks fail.

- cores:

  The number of packages to instrument in parallel, in forked processes.
  Instrumenting byte-compiles the code, which takes long in a build of R
  without optimization, e.g. one built for the coverage of its compiled
  code.

## Value

A list, invisibly, with:

- `packages`: the packages that were instrumented.

- `excluded`: the functions that were not instrumented, by package:
  those in `exclusions` and those with a constant or
  [`UseMethod()`](https://rdrr.io/r/base/UseMethod.html) body.

- `no_srcref`: the functions of base that are not measured, as their
  code differs from the source files, e.g. as it was created by other
  code.

- `uncompiled`: the functions that could not be byte-compiled.

## Details

Functions of base have no source references in a build of R, so they are
read from the source files in `source_dir`, which are used for the
functions whose code is the same as the installed one. Functions without
source references are not measured.

Some functions are not instrumented, so they are not in the coverage,
not even as code that never ran: the functions in `exclusions` (by
default
[`base_r_exclusions()`](https://covr.r-lib.org/dev/reference/base_r_exclusions.md),
those whose code R's own checks inspect), and functions whose body is a
constant or a call to
[`UseMethod()`](https://rdrr.io/r/base/UseMethod.html), which have no
code to cover and whose bodies code also compares. The default arguments
of functions are not traced either, as `R CMD check` compares them with
the documentation.

## Requirements

- Build R from source, with the environment variable
  `R_KEEP_PKG_SOURCE=yes` set so that the packages have source
  references.

- Run `instrument_base_r()` with the R that is instrumented, e.g. the
  `bin/Rscript` of a build that is not installed, as the byte-code in
  the databases depends on the version of R. covr has to be installed in
  a library this R can use, e.g. with `R_LIBS`.

- covr must stay installed at the same path while R is instrumented, as
  instrumented processes load the native code of covr from there.

- This is only supported on Unix-alikes: forked processes of
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  save their counts as they exit.

## Example workflow

    # With R built from `R-devel` in `build`, and covr installed in `lib`, run
    # this with `R_LIBS=lib build/bin/Rscript`:
    library(covr)
    instrument_base_r("R-devel", lib = "build/library", trace_dir = "traces")

    # Then run the checks, saving the counts in `traces`:
    #   COVERAGE_DIR=traces make check

    cov <- base_r_code_coverage("traces", "R-devel")
    report(cov)

    # Restore R, with the same R as above
    uninstrument_base_r(lib = "build/library")

## See also

The article [Coverage of R
itself](https://covr.r-lib.org/articles/base-r.html).

Other base R coverage:
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md),
[`base_r_compiled_coverage()`](https://covr.r-lib.org/dev/reference/base_r_compiled_coverage.md),
[`base_r_exclusions()`](https://covr.r-lib.org/dev/reference/base_r_exclusions.md),
[`uninstrument_base_r()`](https://covr.r-lib.org/dev/reference/uninstrument_base_r.md)
