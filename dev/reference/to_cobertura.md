# Create a Cobertura XML file

Create a cobertura-compliant XML report following [this
DTD](https://github.com/cobertura/cobertura/blob/master/cobertura/src/site/htdocs/xml/coverage-04.dtd).
Because there are *two* DTDs called `coverage-04.dtd` and some tools do
not seem to adhere to either of them, the parser you're using may balk
at the file. Please see [this github
discussion](https://github.com/cobertura/cobertura/issues/425) for
context. Where `covr` doesn't provide a coverage metric (complexity), a
zero is reported.

## Usage

``` r
to_cobertura(cov, filename = "cobertura.xml")
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the Cobertura XML file

## Details

Branch rates are only reported if branches were measured with
`options(covr.branch_coverage = TRUE)` (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)),
otherwise they are zero. Each line where an `if` or
[`switch()`](https://rdrr.io/r/base/switch.html) starts then has
`branch="true"` and a `condition-coverage` such as `"50% (1/2)"`, the
percentage and number of the branches of the `if` and
[`switch()`](https://rdrr.io/r/base/switch.html) calls on the line that
were taken. The branch rate of code without branches is one.

*Note*: This functionality requires the xml2 package be installed.
