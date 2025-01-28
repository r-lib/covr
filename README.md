# covr <img src="man/figures/logo.png" align="right" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/r-lib/covr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/covr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-lib/covr/branch/master/graph/badge.svg)](https://app.codecov.io/gh/r-lib/covr?branch=master)
[![CRAN version](https://www.r-pkg.org/badges/version/covr)](https://cran.r-project.org/package=covr)
<!-- badges: end -->

Track test coverage for your R package and view reports locally or (optionally)
upload the results to [codecov](https://about.codecov.io/) or [coveralls](https://coveralls.io/).

# Installation #

```r
install.packages("covr")

# For devel version
devtools::install_github("r-lib/covr")
```

The easiest way to setup covr on [Github Actions](https://github.com/r-lib/actions/tree/v2-branch/examples#test-coverage-workflow) 
is with [usethis](https://github.com/r-lib/usethis).

```r
usethis::use_github_action("test-coverage")
```

# Usage #

For local development a coverage report can be used to inspect coverage for
each line in your package. *Note* requires the
[DT](https://github.com/rstudio/DT) package to be installed.

```r
library(covr)

# If run with no arguments implicitly calls `package_coverage()`
report()
```

covr also defines an [RStudio Addin](https://rstudio.github.io/rstudioaddins/),
which runs `report()` on the active project. This can be used via the Addin
menu or by binding the action to a
[shortcut](https://rstudio.github.io/rstudioaddins/#keyboard-shorcuts), e.g.
*Ctrl-Shift-C*.

## Interactively ##
```r
# If run with the working directory within the package source.
package_coverage()

# or a package in another directory
cov <- package_coverage("/dir/lintr")

# view results as a data.frame
as.data.frame(cov)

# zero_coverage() shows only uncovered lines.
# If run within RStudio, `zero_coverage()` will open a marker pane with the
# uncovered lines.
zero_coverage(cov)
```

# Exclusions #

`covr` supports a few of different ways of excluding some or all of a file.

## .covrignore file ##

A `.covrignore` file located in your package's root directory can be used to
exclude files or directories.

The lines in the `.covrignore` file are interpreted as a list of file globs to
ignore. It uses the globbing rules in `Sys.glob()`. Any directories listed will
ignore all the files in the directory.

Alternative locations for the file can be set by the environment variable
`COVR_COVRIGNORE` or the R option `covr.covrignore`.

The `.covrignore` file should be added to your `.RBuildignore` file unless you
want to distribute it with your package. If so it can be added to
`inst/.covrignore` instead.


## Function Exclusions ##
The `function_exclusions` argument to `package_coverage()` can be used to
exclude functions by name. This argument takes a vector of regular expressions
matching functions to exclude.

```r
# exclude print functions
package_coverage(function_exclusions = "print\\.")

# exclude `.onLoad` function
package_coverage(function_exclusions = "\\.onLoad")
```

## Line Exclusions ##
The `line_exclusions` argument to `package_coverage()` can be used to exclude some or
all of a file.  This argument takes a list of filenames or named ranges to
exclude.

```r
# exclude whole file of R/test.R
package_coverage(line_exclusions = "R/test.R")

# exclude lines 1 to 10 and 15 from R/test.R
package_coverage(line_exclusions = list("R/test.R" = c(1:10, 15)))

# exclude lines 1 to 10 from R/test.R, all of R/test2.R
package_coverage(line_exclusions = list("R/test.R" = c(1, 10), "R/test2.R"))
```

## Exclusion Comments ##

In addition you can exclude lines from the coverage by putting special comments
in your source code.

This can be done per line.
```r
f1 <- function(x) {
  x + 1 # nocov
}
```

Or by specifying a range with a start and end.
```r
f2 <- function(x) { # nocov start
  x + 2
} # nocov end
```

The patterns used can be specified by setting the global options
`covr.exclude_pattern`, `covr.exclude_start`, `covr.exclude_end`.

NB: The same pattern applies to exclusions in the `src` folder, so skipped lines in, e.g., C code (where comments can start with `//`) should look like `// # nocov`.

# FAQ #
## Will covr work with testthat, RUnit, etc... ##
Covr should be compatible with any testing package, it uses
`tools::testInstalledPackage()` to run your packages tests.

## Will covr work with alternative compilers such as ICC ##
Covr now supports Intel's `icc` compiler, thanks to work contributed by Qin
Wang at Oracle.

Covr is known to work with clang versions `3.5+` and gcc version `4.2+`.

If the appropriate gcov version is not on your path you can set the appropriate
location with the `covr.gcov` options. If you set this path to "" it will turn
_off_ coverage of compiled code.
```r
options(covr.gcov = "path/to/gcov")
```

## How does covr work? ##
`covr` tracks test coverage by modifying a package's code to add tracking calls
to each call.

The vignette
[vignettes/how_it_works.Rmd](https://github.com/r-lib/covr/blob/master/vignettes/how_it_works.Rmd)
contains a detailed explanation of the technique and the rationale behind it.

You can view the vignette from within `R` using

```r
vignette("how_it_works", package = "covr")
```

## Why can't covr run during R CMD check ##
Because covr modifies the package code it is possible there are unknown edge
cases where that modification affects the output. In addition when tracking
coverage for compiled code covr compiles the package without optimization,
which _can_ modify behavior (usually due to package bugs which are masked with
higher optimization levels).

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage> (no longer supported)
- [**R-coverage**](https://web.archive.org/web/20160611114452/http://r2d2.quartzbio.com/posts/r-coverage-docker.html) (no longer supported)

## Code of Conduct

Please note that the covr project is released with a [Contributor Code of Conduct](https://github.com/r-lib/covr/blob/main/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.
