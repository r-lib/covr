# Coverage of the R code of base R

Merges the counts that the processes of an instrumented R (see
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md))
saved in `trace_dir`.

## Usage

``` r
base_r_code_coverage(trace_dir, source_dir)
```

## Arguments

- trace_dir:

  The directory the processes saved their counts in.

- source_dir:

  The directory of the source of R, which the files in the coverage are
  in.

## Value

A coverage object. File names are absolute paths in `source_dir`.

## See also

The article [Coverage of R
itself](https://covr.r-lib.org/articles/base-r.html).

Other base R coverage:
[`base_r_compiled_coverage()`](https://covr.r-lib.org/dev/reference/base_r_compiled_coverage.md),
[`base_r_exclusions()`](https://covr.r-lib.org/dev/reference/base_r_exclusions.md),
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md),
[`uninstrument_base_r()`](https://covr.r-lib.org/dev/reference/uninstrument_base_r.md)
