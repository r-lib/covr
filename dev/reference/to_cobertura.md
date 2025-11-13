# Create a Cobertura XML file

Create a cobertura-compliant XML report following [this
DTD](https://github.com/cobertura/cobertura/blob/master/cobertura/src/site/htdocs/xml/coverage-04.dtd).
Because there are *two* DTDs called `coverage-04.dtd` and some tools do
not seem to adhere to either of them, the parser you're using may balk
at the file. Please see [this github
discussion](https://github.com/cobertura/cobertura/issues/425) for
context. Where `covr` doesn't provide a coverage metric (branch
coverage, complexity), a zero is reported.

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

*Note*: This functionality requires the xml2 package be installed.
