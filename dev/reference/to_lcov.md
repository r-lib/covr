# Create an LCOV tracefile

Write coverage in the LCOV tracefile format described in
[geninfo(1)](https://manpages.debian.org/unstable/lcov/geninfo.1.en.html),
which is read by `genhtml`, Codecov, Coveralls, SonarQube and editor
plugins such as Coverage Gutters.

## Usage

``` r
to_lcov(cov, filename = "lcov.info")
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the LCOV file

## Value

The lines of the LCOV file, invisibly.

## Details

Each source file gets a record with its functions (`FN`, `FNDA`, `FNF`,
`FNH`) and lines (`DA`, `LF`, `LH`). Line counts are those of
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
with `by = "line"`, combined so that each source line has a single `DA`
record: when several functions share a line, the line's count is the
smallest of theirs, so a line only counts as covered if all its code was
run, as in [`report()`](https://covr.r-lib.org/dev/reference/report.md),
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
and [`codecov()`](https://covr.r-lib.org/dev/reference/codecov.md). A
function's count is the largest count of any of its expressions. Branch
coverage is not recorded.

Source file paths (`SF`) are written as covr reports them, for a package
relative to the package root, so tools such as `genhtml` should be run
from that directory.

## Examples

``` r
cov <- code_coverage(
  "f <- function(x) {\n  y <- x + 1\n  y * 2\n}\ng <- function() 1",
  "f(1)"
)
tmp <- tempfile(fileext = ".info")
to_lcov(cov, tmp)
cat(readLines(tmp), sep = "\n")
#> TN:
#> SF:/tmp/RtmpoF9BPH/source.R190546716ca9
#> FN:2,f
#> FN:5,g
#> FNDA:1,f
#> FNDA:0,g
#> FNF:2
#> FNH:1
#> DA:2,1
#> DA:3,1
#> DA:5,0
#> LF:3
#> LH:2
#> end_of_record
```
