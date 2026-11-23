# The functions that are not instrumented by default

The functions of R that
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md)
leaves as they are by default, as R's own checks (`make check-all`)
inspect their code, so they fail if it counts what runs:

## Usage

``` r
base_r_exclusions()
```

## Value

A named list of function names, by package.

## Details

- [`stats::pbinom()`](https://rdrr.io/r/stats/Binomial.html): a
  regression test reads the name of its native routine from its body.

- [`base::simplify2array()`](https://rdrr.io/r/base/lapply.html): a
  regression test compares its
  [`dump()`](https://rdrr.io/r/base/dump.html) and
  [`dput()`](https://rdrr.io/r/base/dput.html).

- `methods:::rematchDefinition()`: it builds the body of rematched S4
  methods from its own code, which
  [`isRematched()`](https://rdrr.io/r/methods/RMethodUtils.html) checks.

- The functions of base that the byte-code compiler inlines
  (`compiler:::safeBaseInternals`), whose tests check that they only
  call [`.Internal()`](https://rdrr.io/r/base/Internal.html). As they
  are inlined, they rarely run anyway.

- The internal generics of base (`.internalGenerics`), which the tests
  of tools check call
  [`.Internal()`](https://rdrr.io/r/base/Internal.html).

## See also

Other base R coverage:
[`base_r_code_coverage()`](https://covr.r-lib.org/dev/reference/base_r_code_coverage.md),
[`base_r_compiled_coverage()`](https://covr.r-lib.org/dev/reference/base_r_compiled_coverage.md),
[`instrument_base_r()`](https://covr.r-lib.org/dev/reference/instrument_base_r.md),
[`uninstrument_base_r()`](https://covr.r-lib.org/dev/reference/uninstrument_base_r.md)

## Examples

``` r
str(base_r_exclusions())
#> List of 3
#>  $ base   : chr [1:30] "simplify2array" "atan2" "besselY" "beta" ...
#>  $ methods: chr "rematchDefinition"
#>  $ stats  : chr "pbinom"

# Also leave out lm()
exclusions <- base_r_exclusions()
exclusions$stats <- c(exclusions$stats, "lm")
```
