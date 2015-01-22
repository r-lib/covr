# Covr #
[![Build Status](https://travis-ci.org/jimhester/covr.png?branch=master)](https://travis-ci.org/jimhester/covr)
[![Coverage Status](https://img.shields.io/coveralls/jimhester/covr.svg?style=flat)](https://coveralls.io/r/jimhester/covr?branch=master)

Test coverage reports for R

# Installation #
## Coveralls.io ##
If you are already using [Travis-CI](https://travis-ci.org) simply add the following lines
to your project's `.travis.yml`.

```yml
install:
  - ./travis-tool.sh github_package jimhester/covr

after_success:
  - Rscript -e 'library(covr);coveralls()'
```

Also you will need to turn on coveralls for your project at <https://coveralls.io/repos/new>.

# Usage #
Using `covr` in an interactive session is also easy.

```r
# if your working directory is in the packages base directory
package_coverage()

# or a package in another directory
package_coverage("lintr")

# zero_coverage() can be used to see which lines are uncovered.
zero_coverage(package_coverage())
```

# Implementation #
`covr` tracks test coverage by augmenting a packages function definitions with counting calls.

The vignette
[vignettes/how_it_works.Rmd](https://github.com/jimhester/covr/blob/master/vignettes/how_it_works.Rmd)
contains a detailed explanation of the technique and the rational behind it.

You can also view the vignette from within `R` using

```r
vignette("how_it_works", package = "covr")
```

# Compiler Compatibility #

If your package has compiled code `covr` requires a compiler that generates
[Gcov](https://gcc.gnu.org/onlinedocs/gcc-4.1.2/gcc/Gcov.html#Gcov) compatible
output.  It is known to work with clang versions `3.5` and gcc versions `4.2`.
It should also work with later versions of both those compilers.

It does _not_ work with `icc`, Intel's compiler.

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
