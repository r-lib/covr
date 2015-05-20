# Covr #
[![wercker status](https://app.wercker.com/status/7b3f03814c6f978cfaad12b4d0378b11/s/master "wercker status")](https://app.wercker.com/project/bykey/7b3f03814c6f978cfaad12b4d0378b11)
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
  - Rscript -e 'library(covr);codecov()'
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
after_success:
  - Rscript -e 'library(covr);coveralls()'
```

For CI systems not supported by coveralls you need to set the `COVERALLS_TOKEN`
environment variable. It is wise to use a [Secure Variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables)
so that it is not revealed publicly.

Also you will need to turn on coveralls for your project at <https://coveralls.io/repos/new>.
[Coveralls](https://coveralls.io/)

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

# Implementation #
`covr` tracks test coverage by augmenting a packages function definitions with
counting calls.

The vignette
[vignettes/how_it_works.Rmd](https://github.com/jimhester/covr/blob/master/vignettes/how_it_works.Rmd)
contains a detailed explanation of the technique and the rational behind it.

You can view the vignette from within `R` using

```r
vignette("how_it_works", package = "covr")
```
# Compatibility #
## Test ##
Covr is compatible with any testing package, it simply executes the code in
`tests/` on your package.

## Compiler ##
If your package has compiled code `covr` requires a compiler that generates
[Gcov](https://gcc.gnu.org/onlinedocs/gcc/Gcov.html) compatible
output.  It is known to work with clang versions `3.5` and gcc versions `4.2`.
It should also work with later versions of both those compilers.

It does _not_ work with `icc`, Intel's compiler.

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
