# Covr #
[![Build Status](https://travis-ci.org/jimhester/covr.svg?branch=master)](https://travis-ci.org/jimhester/covr)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/jimhester/covr?branch=master&svg=true)](https://ci.appveyor.com/project/jimhester/covr)
[![codecov.io](https://codecov.io/github/jimhester/covr/coverage.svg?branch=master)](https://codecov.io/github/jimhester/covr?branch=master)
[![CRAN version](http://www.r-pkg.org/badges/version/covr)](http://cran.rstudio.com/web/packages/covr/index.html)

Track test coverage for your R package and (optionally) upload the results to
[coveralls](https://coveralls.io/) or [codecov](https://codecov.io/).

# Installation #
## Codecov ##
If you are already using [Travis-CI](https://travis-ci.org) or [Appveyor CI](http://www.appveyor.com) add the
following to your project's `.travis.yml` to track your coverage results
over time with [Codecov](https://codecov.io).

```yml
r_github_packages:
  - jimhester/covr

after_success:
  - Rscript -e 'covr::codecov()'
```

To use a different CI service or call `codecov()` locally you can set the
environment variable `CODECOV_TOKEN` to the token generated on codecov.io.

Codecov currently has support for the following CI systems (\* denotes support
without needing `CODECOV_TOKEN`).

- [Jenkins](https://jenkins-ci.org)
- [Travis CI\*](https://travis-ci.com)
- [Codeship](https://www.codeship.io/)
- [Circleci\*](https://circleci.com)
- [Semaphore](https://semaphoreapp.com)
- [drone.io](https://drone.io)
- [AppVeyor\*](http://www.appveyor.com)
- [Wercker](http://wercker.com)

You will also need to enable the repository on [Codecov](https://codecov.io/).

## Coveralls ##

Alternatively you can upload your results to [Coveralls](https://coveralls.io/)
using `coveralls()`.

```yml
r_github_packages:
  - jimhester/covr

after_success:
  - Rscript -e 'covr::coveralls()'
```

For CI systems not supported by coveralls you need to set the `COVERALLS_TOKEN`
environment variable. It is wise to use a [Secure Variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables)
so that it is not revealed publicly.

Also you will need to turn on coveralls for your project at <https://coveralls.io/repos/new>.

# Interactive Usage #

## Shiny Application ##
A [shiny](http://shiny.rstudio.com/) Application can be used to
view coverage per line.
```r
cov <- package_coverage()

shine(cov)
```

If used with `type = "all"` the Shiny Application will allow you to
interactively toggle between Test, Vignette and Example coverage.

```r
cov <- package_coverage(type = "all")

shine(cov)
```

## R Command Line ##
```r
# if your working directory is in the packages base directory
package_coverage()

# or a package in another directory
cov <- package_coverage("lintr")

# view results as a data.frame
as.data.frame(cov)

# zero_coverage() can be used to filter only uncovered lines.
zero_coverage(cov)
```

# Exclusions #

`covr` supports a couple of different ways of excluding some or all of a file.

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


# FAQ #
## Will covr work with testthat, RUnit, etc... ##
Covr should be compatible with _any_ testing framework, it uses
`tools::testInstalledPackage()` to run your packages tests.

## Will covr work with alternative compilers such as ICC ##
Covr will _not_ work with `icc`, Intel's compiler as it does not have
[Gcov](https://gcc.gnu.org/onlinedocs/gcc/Gcov.html) compatible output.

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
[vignettes/how_it_works.Rmd](https://github.com/jimhester/covr/blob/master/vignettes/how_it_works.Rmd)
contains a detailed explanation of the technique and the rational behind it.

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
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
