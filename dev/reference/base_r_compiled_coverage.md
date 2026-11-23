# Coverage of the compiled code of R

Computes the coverage of the C, C++ and Fortran code of R itself, from
the counts that gcov records while R runs, e.g. under `make check`. This
is for measuring R, not packages: use
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
for those.

## Usage

``` r
base_r_compiled_coverage(
  build_dir,
  source_dir,
  exclude = "tests",
  cores = 1L,
  batch_size = 50L,
  quiet = TRUE,
  gcov_path = resolve_gcov(),
  gcov_args = getOption("covr.gcov_args", NULL)
)
```

## Arguments

- build_dir:

  The directory R was configured and built in, after the counts were
  collected.

- source_dir:

  The directory with the R sources it was built from.

- exclude:

  Directories relative to `source_dir` whose files are left out of the
  coverage.

- cores:

  The number of parallel processes to run gcov in. Forking is not
  available on Windows.

- batch_size:

  The number of objects gcov is run on at a time.

- quiet:

  Whether to hide the progress messages.

- gcov_path:

  The path of the gcov executable.

- gcov_args:

  Extra arguments for gcov.

## Value

A coverage object of the lines of the files in `source_dir`, with
absolute file names.

## Details

All objects with a `.gcno` file are measured, also if no process ran
them and no `.gcda` file was written, so their lines count as not
covered. gcov is run in a temporary directory, in batches of
`batch_size` objects that may run in `cores` parallel processes, so
neither the build nor the source tree get any files. Headers outside of
`source_dir`, and generated files in the build tree, are dropped.

## Requirements

- R must be built from source, out of tree, with `--coverage` in the
  compiler flags, e.g.
  `CFLAGS="-O0 --coverage" FFLAGS="-O0 --coverage" LDFLAGS=--coverage`.
  Every object in `build_dir` then has a `.gcno` file with its layout,
  and processes of that R write `.gcda` files of counts when they exit.

- `gcov` must be available, see `covr.gcov` in
  [covr-package](https://covr.r-lib.org/dev/reference/covr-package.md).

- Processes forked by
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  leave with `_exit()` and don't write their gcov counts, unless R code
  was instrumented by
  [`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md)
  on a build with `--coverage`.

- This is only supported on Unix-alikes.

## Example workflow

    # Build R with coverage flags in `build_dir` from the sources in
    # `source_dir`, and run its checks: `make check`
    cov <- base_r_compiled_coverage("build", "R-devel", cores = 4)
    report(cov)

## See also

The article [Coverage of R
itself](https://covr.r-lib.org/articles/base-r.html).

Other base R coverage:
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md),
[`base_r_exclusions()`](https://covr.r-lib.org/dev/reference/base_r_exclusions.md),
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md),
[`uninstrument_base_r()`](https://covr.r-lib.org/dev/reference/uninstrument_base_r.md)
