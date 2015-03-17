# Covr #
[![Build Status](https://travis-ci.org/jimhester/covr.png?branch=master)](https://travis-ci.org/jimhester/covr)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/jimhester/covr?branch=master)](https://ci.appveyor.com/project/jimhester/covr)
[![Coverage Status](https://img.shields.io/coveralls/jimhester/covr.svg?style=flat)](https://coveralls.io/r/jimhester/covr?branch=master)

Track test coverage for your R package and (optionally) upload the results to
[coveralls](https://coveralls.io/) or [codecov](https://codecov.io/).

# Compatibility #
Covr is compatible with any testing package, it simply executes the code in
`tests/` on your package.

# Installation #
## Coveralls.io ##
If you are already using [Travis-CI](https://travis-ci.org) add the
following to your project's `.travis.yml` to track your coverage results
over time with [coveralls][].

```yml
r_github_packages:
  - jimhester/covr

after_success:
  - Rscript -e 'library(covr);coveralls()'
```

To use a different CI service, you need to specify your secret repo token for
the repository, found at the bottom of your repository's page on Coveralls.
Your `after_success` would then look like this:

```yml
after_success:
  - Rscript -e 'library(covr);coveralls(repo_token = "your_secret_token")'
```

If you are using the secret repo token it is wise to use a [Secure
Variable](http://docs.travis-ci.com/user/environment-variables/#Secure-Variables)
so that it cannot be used maliciously.

Also you will need to turn on coveralls for your project at <https://coveralls.io/repos/new>.

## Codecov.io ##
Alternatively you can track your coverage results using Codecov, which supports
a large number of CI systems out of the box

- [Jenkins](https://jenkins-ci.org)
- [Travis CI](https://travis-ci.com)
- [Codeship](https://www.codeship.io/)
- [Circleci](https://circleci.com)
- [Semaphore](https://semaphoreapp.com)
- [drone.io](https://drone.io)
- [AppVeyor](http://www.appveyor.com)
- [Wercker](http://wercker.com)

It also supports uploading coverage results directly from your computer.

For all of the cases include the following in your build script.
```r
library(covr)
codecov()
```

# Usage #
Iterative usage of `covr`.

## REPL ##
```r
# if your working directory is in the packages base directory
package_coverage()

# or a package in another directory
package_coverage("lintr")

# zero_coverage() can be used to see only uncovered lines.
zero_coverage(package_coverage())
```

## Shiny App ##
A [shiny](http://shiny.rstudio.com/) application can also be used to
view coverage per line.
```r
cov <- package_coverage()

shine(cov)
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

# Compiler Compatibility #

If your package has compiled code `covr` requires a compiler that generates
[Gcov](https://gcc.gnu.org/onlinedocs/gcc/Gcov.html) compatible
output.  It is known to work with clang versions `3.5` and gcc versions `4.2`.
It should also work with later versions of both those compilers.

It does _not_ work with `icc`, Intel's compiler.

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
