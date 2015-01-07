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

# Alternative Coverage Tools #
- <https://github.com/MangoTheCat/testCoverage>
- <http://r2d2.quartzbio.com/posts/r-coverage-docker.html>
