# Deprecated functions

These functions are deprecated and warn once per session. They take the
same arguments and return the same value as the functions that replace
them:

- `to_cobertura()` is now
  [`cobertura()`](https://covr.r-lib.org/dev/reference/cobertura.md).

- `to_sonarqube()` is now
  [`sonarqube()`](https://covr.r-lib.org/dev/reference/sonarqube.md).

## Usage

``` r
to_cobertura(cov, filename = "cobertura.xml")

to_sonarqube(cov, filename = "sonarqube.xml", path_prefix = NULL)
```

## Arguments

- cov:

  the coverage object returned from
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)

- filename:

  the name of the output file

- path_prefix:

  SonarQube expects file paths relative to the project's base directory.
  By default the paths are relative to the package root (e.g.
  `R/foo.R`), which is correct when the package is the root of the
  SonarQube project. If the package is in a subdirectory of the project,
  set `path_prefix` to that subdirectory (e.g. `"pkg"` gives
  `pkg/R/foo.R`).
