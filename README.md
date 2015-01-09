# Covr #
[![Build Status](https://travis-ci.org/jimhester/covr.png?branch=master)](https://travis-ci.org/jimhester/covr)
[![Coverage Status](https://img.shields.io/coveralls/jimhester/covr.svg)](https://coveralls.io/r/jimhester/covr?branch=master)

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
Using `covr` in an interactive session is easy.

```r
# if you want the raw package output
cov <- package_coverage()

# if you want the overall percentage coverage of your package
percent_coveage(cov)

# if you only want to see those lines which are uncovered
zero_coverage(cov)
```

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
