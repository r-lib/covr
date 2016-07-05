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
47 packages

## betalink (2.2.1)
Maintainer: Timothee Poisot <tim@poisotlab.io>

0 errors | 0 warnings | 1 note 

```
checking DESCRIPTION meta-information ... NOTE
Checking should be performed on sources prepared by ‘R CMD build’.
```

## bold (0.3.5)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/bold/issues

0 errors | 0 warnings | 0 notes

## brranching (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/brranching/issues

0 errors | 0 warnings | 0 notes

## callr (1.0.0)
Maintainer: Gábor Csárdi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/callr/issues

0 errors | 0 warnings | 0 notes

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

## DBI (0.4-1)
Maintainer: Kirill Müller <krlmlr+r@mailbox.org>  
Bug reports: https://github.com/rstats-db/DBI/issues

0 errors | 0 warnings | 1 note 

```
checking S3 generic/method consistency ... NOTE
Found the following apparent S3 methods exported but not registered:
  print.list.pairs
See section ‘Registering S3 methods’ in the ‘Writing R Extensions’
manual.
```

## dendextend (1.1.8)
Maintainer: Tal Galili <tal.galili@gmail.com>  
Bug reports: https://github.com/talgalili/dendextend/issues

0 errors | 0 warnings | 3 notes

```
checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘ggdendro’ ‘labeltodendro’ ‘dendroextras’

checking installed package size ... NOTE
  installed size is  5.7Mb
  sub-directories of 1Mb or more:
    R     1.0Mb
    doc   4.0Mb

checking Rd cross-references ... NOTE
Packages unavailable to check Rd xrefs: ‘WGCNA’, ‘dendroextras’, ‘moduleColor’, ‘distory’, ‘ggdendro’
```

## devtools (1.11.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/devtools/issues

0 errors | 0 warnings | 0 notes

## discgolf (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/sckott/discgolf/issues

0 errors | 0 warnings | 0 notes

## EpiModel (1.2.6)
Maintainer: Samuel Jenness <samuel.m.jenness@emory.edu>  
Bug reports: https://github.com/statnet/EpiModel/issues

0 errors | 0 warnings | 0 notes

## geojsonlint (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropenscilabs/geojsonlint/issues

0 errors | 0 warnings | 0 notes

## ggplot2 (2.1.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/ggplot2/issues

0 errors | 0 warnings | 0 notes

## googlesheets (0.2.0)
Maintainer: Jennifer Bryan <jenny@stat.ubc.ca>  
Bug reports: https://github.com/jennybc/googlesheets/issues

0 errors | 0 warnings | 0 notes

## gtable (0.2.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>

0 errors | 0 warnings | 0 notes

## jqr (0.2.3)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/jqr/issues

0 errors | 0 warnings | 0 notes

## lawn (0.1.7)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/lawn/issues

0 errors | 0 warnings | 0 notes

## lazyeval (0.2.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>

0 errors | 0 warnings | 0 notes

## loo (0.1.6)
Maintainer: Jonah Gabry <jsg2201@columbia.edu>  
Bug reports: https://github.com/stan-dev/loo/issues

0 errors | 0 warnings | 0 notes

## lubridate (1.5.6)
Maintainer: Vitalie Spinu <spinuvit@gmail.com>  
Bug reports: https://github.com/hadley/lubridate/issues

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘timeDate’ ‘its’ ‘tis’ ‘timeSeries’ ‘fts’ ‘tseries’
```

## Momocs (1.0.0)
Maintainer: Vincent Bonhomme <bonhomme.vincent@gmail.com>  
Bug reports: https://github.com/vbonhomme/Momocs/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.8Mb
  sub-directories of 1Mb or more:
    R      1.7Mb
    data   1.1Mb
    doc    2.2Mb
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

## optiRum (0.37.3)
Maintainer: Stephanie Locke <stephanie.g.locke@gmail.com>  
Bug reports: https://github.com/stephlocke/optiRum/issues

0 errors | 0 warnings | 0 notes

## originr (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropenscilabs/originr/issues

0 errors | 0 warnings | 0 notes

## pangaear (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/pangaear/issues

0 errors | 0 warnings | 0 notes

## plyr (1.8.4)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/plyr/issues

0 errors | 0 warnings | 0 notes

## pmc (1.0.2)
Maintainer: Carl Boettiger <cboettig@gmail.com>  
Bug reports: https://github.com/cboettig/pmc/issues

0 errors | 0 warnings | 0 notes

## prof.tree (0.1.0)
Maintainer: Artem Kelvtsov <a.a.klevtsov@gmail.com>  
Bug reports: https://github.com/artemklevtsov/prof.tree/issues

0 errors | 0 warnings | 0 notes

## purrr (0.2.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/purrr/issues

0 errors | 0 warnings | 0 notes

## rematch (1.0.1)
Maintainer: Gabor Csardi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/rematch/issues

0 errors | 0 warnings | 0 notes

## rnoaa (0.5.6)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/rnoaa/issues

0 errors | 0 warnings | 0 notes

## rnpn (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>

0 errors | 0 warnings | 0 notes

## rodham (0.0.2)
Maintainer: John Coene <jcoenep@gmail.com>

0 errors | 0 warnings | 0 notes

## rvertnet (0.4.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rvertnet/issues

0 errors | 0 warnings | 0 notes

## rvest (0.3.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/rvest/issues

0 errors | 0 warnings | 1 note 

```
checking dependencies in R code ... NOTE
Missing or unexported object: ‘xml2::xml_find_first’
```

## rvg (0.0.9)
Maintainer: David Gohel <david.gohel@ardata.fr>  
Bug reports: https://github.com/davidgohel/rvg/issues

0 errors | 0 warnings | 0 notes

## scales (0.4.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/scales/issues

0 errors | 0 warnings | 0 notes

## simmer (3.2.1)
Maintainer: Iñaki Ucar <i.ucar86@gmail.com>  
Bug reports: https://github.com/Enchufa2/simmer/issues

0 errors | 0 warnings | 0 notes

## SpaDES (1.1.4)
Maintainer: Alex M Chubaty <alexander.chubaty@canada.ca>  
Bug reports: https://github.com/PredictiveEcology/SpaDES/issues

0 errors | 0 warnings | 2 notes

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘fastshp’

checking installed package size ... NOTE
  installed size is  5.6Mb
  sub-directories of 1Mb or more:
    R     2.8Mb
    doc   2.0Mb
```

## spocc (0.5.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/spocc/issues

0 errors | 0 warnings | 0 notes

## svglite (1.1.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/svglite/issues

0 errors | 0 warnings | 0 notes

## taxize (0.7.8)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/taxize/issues

0 errors | 0 warnings | 0 notes

## testthat (1.0.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/testthat/issues

0 errors | 0 warnings | 0 notes

## tidyr (0.5.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/tidyr/issues

0 errors | 0 warnings | 1 note 

```
checking dependencies in R code ... NOTE
Missing or unexported object: ‘dplyr::everything’
```

## tokenizers (0.1.2)
Maintainer: Lincoln Mullen <lincoln@lincolnmullen.com>  
Bug reports: https://github.com/lmullen/tokenizers/issues

0 errors | 0 warnings | 0 notes

## traits (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/traits/issues

0 errors | 0 warnings | 0 notes

## vembedr (0.1.0)
Maintainer: Ian Lyttle <ian.lyttle@schneider-electric.com>  
Bug reports: https://github.com/ijlyttle/vembedr/issues

0 errors | 0 warnings | 0 notes

## xmlparsedata (1.0.1)
Maintainer: Gábor Csárdi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/xmlparsedata/issues

0 errors | 0 warnings | 0 notes

