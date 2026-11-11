# Colors for color vision deficiency

`colorblind_palette` has colors for the `covr.report_colors` option that
are easier to tell apart with color vision deficiency than the default
green and red: blue for covered code, yellow for partial coverage and
vermillion for missed code, from the Okabe-Ito palette. They are used in
[`report()`](https://covr.r-lib.org/dev/reference/report.md),
[`file_report()`](https://covr.r-lib.org/dev/reference/file_report.md)
and the coverage percentages printed in the console.

## Usage

``` r
colorblind_palette
```

## Format

A named character vector with elements `covered`, `partial` and
`missed`.

## Details

To set the colors in your `.Rprofile` without loading covr, copy the
values.

## Examples

``` r
colorblind_palette
#>   covered   partial    missed 
#> "#0072B2" "#F0E442" "#D55E00" 
if (FALSE) { # \dontrun{
options(covr.report_colors = covr::colorblind_palette)
report()
} # }
```
