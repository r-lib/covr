# Create a SonarQube Generic XML file for test coverage according to <https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/generic-test-data> Based on cobertura.R

This functionality requires the xml2 package be installed.

## Usage

``` r
to_sonarqube(cov, filename = "sonarqube.xml", path_prefix = NULL)
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the SonarQube Generic XML file

- path_prefix:

  SonarQube expects file paths relative to the project's base directory.
  By default the paths are relative to the package root (e.g.
  `R/foo.R`), which is correct when the package is the root of the
  SonarQube project. If the package is in a subdirectory of the project,
  set `path_prefix` to that subdirectory (e.g. `"pkg"` gives
  `pkg/R/foo.R`).

## Author

Talkdesk Inc.
