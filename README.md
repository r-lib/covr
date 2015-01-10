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
# if you are in the packages base directory
package_coverage()

# or a package in another directory
package_coverage("lintr")

# use zero coverage to see which lines are uncovered.
zero_coverage(package_coverage())
```

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
