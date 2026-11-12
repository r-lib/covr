# Create a SonarQube Generic XML file

Write coverage in the [generic test
data](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/generic-test-data)
XML format read by SonarQube.

## Usage

``` r
sonarqube(x, file = "sonarqube.xml", path_prefix = NULL)
```

## Arguments

- x:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- file:

  the name of the SonarQube Generic XML file

- path_prefix:

  SonarQube expects file paths relative to the project's base directory.
  By default the paths are relative to the package root (e.g.
  `R/foo.R`), which is correct when the package is the root of the
  SonarQube project. If the package is in a subdirectory of the project,
  set `path_prefix` to that subdirectory (e.g. `"pkg"` gives
  `pkg/R/foo.R`).

## Value

The XML document (an `xml2` document), invisibly, after writing it to
`file`.

## Details

Every line with coverage is reported as a `lineToCover` with its
`lineNumber` and whether it is `covered`, including the lines of
compiled code. Each line is reported once: when several functions share
a line, it is only covered if all its code was run, as in
[`report()`](https://covr.r-lib.org/dev/reference/report.md) and
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md).

Branches are only reported if they were measured with
`options(covr.branch_coverage = TRUE)` (see
[covr.branch_coverage](https://covr.r-lib.org/dev/reference/covr.branch_coverage.md)).
A line where an `if` or [`switch()`](https://rdrr.io/r/base/switch.html)
starts then also has `branchesToCover`, the number of branches of the
`if` and [`switch()`](https://rdrr.io/r/base/switch.html) calls on the
line, and `coveredBranches`, how many of them were taken.

This functionality requires the xml2 package be installed.

## Author

Talkdesk Inc.
