# Create a coverage badge

Write an SVG badge showing the percent coverage, in the style of the
badges made by Codecov and shields.io, so a README can show the coverage
of a package without uploading it to a coverage service. The badge is
made locally and doesn't need a network connection.

## Usage

``` r
to_badge(cov, filename = "coverage.svg", label = "coverage")
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the SVG file

- label:

  the text on the left side of the badge

## Value

The lines of the SVG file, invisibly.

## Details

The coverage is that of
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
rounded down to a whole percent so that only fully covered code shows
100%. The badge is green for coverage of 90% or more, yellow for 75% or
more and red below that, the same thresholds used by
[`report()`](https://covr.r-lib.org/dev/reference/report.md). Coverage
without any lines of code, such as that of a package with no R code,
shows as `unknown` on a gray badge.

The badge is a plain file, so on a continuous integration service it
needs to be stored somewhere that the README can link to, e.g. committed
to a separate branch of the repository. See the README of covr for an
example GitHub Actions workflow.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) {\n  y <- x + 1\n  if (y > 0) {\n    'yes'\n  } else {\n    'no'\n  }\n}",
  "f(1)"
)
tmp <- tempfile(fileext = ".svg")
to_badge(cov, tmp)
cat(readLines(tmp), sep = "\n")
#> <svg xmlns="http://www.w3.org/2000/svg" width="97" height="20" role="img" aria-label="coverage: 75%">
#> <title>coverage: 75%</title>
#> <linearGradient id="s" x2="0" y2="100%">
#> <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
#> <stop offset="1" stop-opacity=".1"/>
#> </linearGradient>
#> <clipPath id="r">
#> <rect width="97" height="20" rx="3" fill="#fff"/>
#> </clipPath>
#> <g clip-path="url(#r)">
#> <rect width="61" height="20" fill="#555"/>
#> <rect x="61" width="36" height="20" fill="#dfb317"/>
#> <rect width="97" height="20" fill="url(#s)"/>
#> </g>
#> <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="11">
#> <text aria-hidden="true" x="30.5" y="15" fill="#010101" fill-opacity=".3" textLength="50.2">coverage</text>
#> <text x="30.5" y="14" textLength="50.2">coverage</text>
#> <text aria-hidden="true" x="79" y="15" fill="#010101" fill-opacity=".3" textLength="25.8">75%</text>
#> <text x="79" y="14" textLength="25.8">75%</text>
#> </g>
#> </svg>
```
