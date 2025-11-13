# Create a SonarQube Generic XML file for test coverage according to https://docs.sonarqube.org/latest/analysis/generic-test/ Based on cobertura.R

This functionality requires the xml2 package be installed.

## Usage

``` r
to_sonarqube(cov, filename = "sonarqube.xml")
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the SonarQube Generic XML file

## Author

Talkdesk Inc.
