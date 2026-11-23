# Restore the base packages that were instrumented

Undoes
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md):
the loader scripts of the packages are restored and the instrumented
code is removed. Run it with the same R as
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md),
after
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md),
which reads the counters that this removes once no package is
instrumented. base can only be restored with all the other instrumented
packages.

## Usage

``` r
uninstrument_base_r(lib = R.home("library"), packages = base_r_packages(lib))
```

## Arguments

- lib:

  The library of the base packages of R.

- packages:

  The packages to restore.

## Value

`NULL`, invisibly.

## See also

The article [Coverage of R
itself](https://covr.r-lib.org/articles/base-r.html).

Other base R coverage:
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md),
[`base_r_compiled_coverage()`](https://covr.r-lib.org/dev/reference/base_r_compiled_coverage.md),
[`base_r_exclusions()`](https://covr.r-lib.org/dev/reference/base_r_exclusions.md),
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md)
