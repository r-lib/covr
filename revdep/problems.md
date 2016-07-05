# Setup

## Platform

|setting  |value                        |
|:--------|:----------------------------|
|version  |R version 3.3.0 (2016-05-03) |
|system   |x86_64, darwin13.4.0         |
|ui       |X11                          |
|language |(EN)                         |
|collate  |en_US.UTF-8                  |
|tz       |America/New_York             |
|date     |2016-06-21                   |

## Packages

|package    |*  |version     |date       |source                             |
|:----------|:--|:-----------|:----------|:----------------------------------|
|covr       |   |2.0.1.9000  |2016-06-21 |local (jimhester/covr@NA)          |
|crayon     |   |1.3.1       |2015-07-13 |cran (@1.3.1)                      |
|devtools   |*  |1.11.1.9000 |2016-06-20 |local (jimhester/devtools@aaa4b61) |
|DT         |   |0.1         |2015-06-09 |cran (@0.1)                        |
|htmltools  |   |0.3.5       |2016-03-21 |cran (@0.3.5)                      |
|httr       |   |1.2.0       |2016-06-15 |cran (@1.2.0)                      |
|jsonlite   |   |0.9.22      |2016-06-15 |cran (@0.9.22)                     |
|knitr      |   |1.13        |2016-05-09 |cran (@1.13)                       |
|memoise    |   |1.0.0       |2016-01-29 |cran (@1.0.0)                      |
|R6         |   |2.1.2       |2016-01-26 |cran (@2.1.2)                      |
|rex        |   |1.1.1       |2016-03-11 |cran (@1.1.1)                      |
|rmarkdown  |   |0.9.6       |2016-05-01 |cran (@0.9.6)                      |
|rstudioapi |   |0.5         |2016-01-24 |cran (@0.5)                        |
|shiny      |   |0.13.2      |2016-03-28 |cran (@0.13.2)                     |
|testthat   |   |1.0.2       |2016-04-23 |cran (@1.0.2)                      |
|withr      |   |1.0.2       |2016-06-20 |cran (@1.0.2)                      |

# Check results
2 packages with problems

## cellranger (1.0.0)
Maintainer: Jennifer Bryan <jenny@stat.ubc.ca>  
Bug reports: https://github.com/jennybc/cellranger/issues

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  > library(cellranger)
  > 
  > test_check("cellranger")
  1. Failure: Print method works (@test-cell-specification.R#163) ----------------
  cell_limits(c(NA, 7), c(3, NA)) produced no output
  
  
  testthat results ================================================================
  OK: 93 SKIPPED: 0 FAILED: 1
  1. Failure: Print method works (@test-cell-specification.R#163) 
  
  Error: testthat unit tests failed
  Execution halted
```

## netdiffuseR (1.16.5)
Maintainer: George Vega Yon <g.vegayon@gmail.com>  
Bug reports: https://github.com/USCCANA/netdiffuseR/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘netdiffuseR’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/netdiffuseR.Rcheck/00install.out’ for details.
```

