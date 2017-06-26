# Setup

## Platform

|setting  |value                                       |
|:--------|:-------------------------------------------|
|version  |R version 3.4.0 Patched (2017-05-10 r72669) |
|system   |x86_64, darwin15.6.0                        |
|ui       |X11                                         |
|language |(EN)                                        |
|collate  |en_US.UTF-8                                 |
|tz       |America/New_York                            |
|date     |2017-06-26                                  |

## Packages

|package     |*  |version |date       |source         |
|:-----------|:--|:-------|:----------|:--------------|
|covr        |   |2.2.2   |2017-01-05 |cran (@2.2.2)  |
|crayon      |   |1.3.2   |2016-06-28 |cran (@1.3.2)  |
|devtools    |*  |1.13.2  |2017-06-02 |cran (@1.13.2) |
|DT          |   |0.2     |2016-08-09 |cran (@0.2)    |
|htmltools   |   |0.3.6   |2017-04-28 |cran (@0.3.6)  |
|htmlwidgets |   |0.8     |2016-11-09 |cran (@0.8)    |
|httr        |   |1.2.1   |2016-07-03 |CRAN (R 3.4.0) |
|jsonlite    |   |1.5     |2017-06-01 |cran (@1.5)    |
|knitr       |   |1.16    |2017-05-18 |cran (@1.16)   |
|memoise     |   |1.1.0   |2017-04-21 |CRAN (R 3.4.0) |
|R6          |   |2.2.2   |2017-06-17 |cran (@2.2.2)  |
|rex         |   |1.1.1   |2016-12-05 |cran (@1.1.1)  |
|rmarkdown   |   |1.6     |2017-06-15 |cran (@1.6)    |
|rstudioapi  |   |0.6     |2016-06-27 |CRAN (R 3.4.0) |
|shiny       |   |1.0.3   |2017-04-26 |cran (@1.0.3)  |
|testthat    |   |1.0.2   |2016-04-23 |cran (@1.0.2)  |
|withr       |   |1.0.2   |2016-06-20 |CRAN (R 3.4.0) |
|xml2        |   |1.1.1   |2017-01-24 |cran (@1.1.1)  |

# Check results

22 packages with problems

|package        |version | errors| warnings| notes|
|:--------------|:-------|------:|--------:|-----:|
|antaresViz     |0.10    |      1|        0|     0|
|autothresholdr |0.5.0   |      1|        0|     0|
|biolink        |0.1.2   |      1|        0|     0|
|broom          |0.4.2   |      2|        0|     0|
|ClusterR       |1.0.5   |      1|        0|     0|
|dbplyr         |1.0.0   |      1|        0|     0|
|DepthProc      |2.0.1   |      1|        0|     1|
|diceR          |0.1.0   |      1|        0|     0|
|dplyr          |0.7.1   |      1|        0|     0|
|easyml         |0.1.0   |      1|        0|     0|
|FedData        |2.4.5   |      1|        0|     0|
|FSelectorRcpp  |0.1.3   |      1|        0|     1|
|geofacet       |0.1.4   |      1|        0|     0|
|KernelKnn      |1.0.5   |      1|        0|     0|
|lawn           |0.3.0   |      1|        0|     0|
|mlrMBO         |1.1.0   |      0|        1|     0|
|nandb          |0.2.0   |      1|        0|     0|
|OpenImageR     |1.0.6   |      1|        0|     0|
|RSQLServer     |0.3.0   |      1|        0|     0|
|textTinyR      |1.0.7   |      1|        0|     0|
|valr           |0.3.0   |      1|        0|     0|
|Wmisc          |0.3.2   |      1|        0|     2|

## antaresViz (0.10)
Maintainer: Francois Guillem <francois.guillem@rte-france.com>
Bug reports: https://github.com/rte-antares-rpackage/antaresViz/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required and available but unsuitable version: ‘leaflet.minicharts’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## autothresholdr (0.5.0)
Maintainer: Rory Nolan <rorynoolan@gmail.com>
Bug reports: https://www.github.com/rorynolan/autothresholdr/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required but not available: ‘EBImage’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## biolink (0.1.2)
Maintainer: Aaron Wolen <aaron@wolen.com>

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’ [46s/68s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
                                                                      ^
  tests/testthat/test-utils.R:27:52: style: Opening curly braces should never go on their own line and should always be followed by a new line.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                     ^
  tests/testthat/test-utils.R:27:67: style: Closing curly-braces should always be on their own line, unless it's followed by an else.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                                    ^


  testthat results ================================================================
  OK: 118 SKIPPED: 0 FAILED: 1
  1. Failure: Package Style (@test-style.r#4)

  Error: testthat unit tests failed
  Execution halted
```

## broom (0.4.2)
Maintainer: David Robinson <admiral.david@gmail.com>
Bug reports: http://github.com/tidyverse/broom/issues

2 errors | 0 warnings | 0 notes

```
checking examples ... ERROR
Running examples in ‘broom-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: gmm_tidiers
> ### Title: Tidying methods for generalized method of moments "gmm" objects
> ### Aliases: glance.gmm gmm_tidiers tidy.gmm
>
> ### ** Examples
... 58 lines ...
+     mutate(variable = reorder(variable, estimate)) %>%
+     ggplot(aes(estimate, variable)) +
+     geom_point() +
+     geom_errorbarh(aes(xmin = conf.low, xmax = conf.high)) +
+     facet_wrap(~ term) +
+     geom_vline(xintercept = 0, color = "red", lty = 2)
+ }
Error in `colnames<-`(`*tmp*`, value = c("conf.low", "conf.high")) :
  attempt to set 'colnames' on an object with less than two dimensions
Calls: tidy -> tidy.gmm -> process_lm -> colnames<-
Execution halted

checking tests ... ERROR
  Running ‘test-all.R’ [16s/24s]
Running the tests in ‘tests/test-all.R’ failed.
Complete output:
  > library(testthat)
  > test_check("broom")
  Loading required package: broom
  Loading required namespace: gam
  error occurred during calling the sampler; sampling not done
  Error in check_stanfit(stanfit) :
    Invalid stanfit object produced please report bug
  Calls: test_check ... eval -> stan_glmer -> stan_glm.fit -> check_stanfit
  testthat results ================================================================
  OK: 451 SKIPPED: 0 FAILED: 0
  Execution halted
```

## ClusterR (1.0.5)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>
Bug reports: https://github.com/mlampros/ClusterR/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available: ‘gmp’ ‘FD’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## dbplyr (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>
Bug reports: https://github.com/tidyverse/dplyr/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required and available but unsuitable version: ‘dplyr’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## DepthProc (2.0.1)
Maintainer: Zygmunt Zawadzki <zygmunt@zstat.pl>

1 error  | 0 warnings | 1 note

```
checking whether package ‘DepthProc’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/DepthProc.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Package suggested but not available for checking: ‘fda’
```

## diceR (0.1.0)
Maintainer: Derek Chiu <dchiu@bccrc.ca>
Bug reports: https://github.com/AlineTalhouk/diceR/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available:
  ‘flux’ ‘apcluster’ ‘infotheo’ ‘blockcluster’ ‘clue’ ‘clusterCrit’
  ‘clValid’ ‘klaR’ ‘quantable’ ‘RankAggreg’ ‘sigclust’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## dplyr (0.7.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>
Bug reports: https://github.com/tidyverse/dplyr/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘dplyr’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/dplyr.Rcheck/00install.out’ for details.
```

## easyml (0.1.0)
Maintainer: Woo-Young Ahn <ahn.280@osu.edu>
Bug reports: https://github.com/CCS-Lab/easyml/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available:
  ‘darch’ ‘dummies’ ‘glinternet’ ‘pbmcapply’ ‘scorer’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## FedData (2.4.5)
Maintainer: R. Kyle Bocinsky <bocinsky@gmail.com>
Bug reports: https://github.com/bocinsky/FedData/issues

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’ [6s/51s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
  Attaching package: 'raster'

  The following objects are masked from 'package:aqp':

      metadata, metadata<-

  testthat results ================================================================
  OK: 24 SKIPPED: 0 FAILED: 1
  1. Failure: The Daymet tiles are available at the correct URL (@test.DAYMET.R#10)

  Error: testthat unit tests failed
  In addition: Warning message:
  In .Internal(get(x, envir, mode, inherits)) :
    closing unused connection 3 (ftp://ftp.ncdc.noaa.gov/pub/data/paleo/treering/chronologies/)
  Execution halted
```

## FSelectorRcpp (0.1.3)
Maintainer: Zygmunt Zawadzki <zygmunt@zstat.pl>
Bug reports: https://github.com/mi2-warsaw/FSelectorRcpp/issues

1 error  | 0 warnings | 1 note

```
checking whether package ‘FSelectorRcpp’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/FSelectorRcpp.Rcheck/00install.out’ for details.

checking package dependencies ... NOTE
Package suggested but not available for checking: ‘RTCGA.rnaseq’
```

## geofacet (0.1.4)
Maintainer: Ryan Hafen <rhafen@gmail.com>

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘testthat.R’ [129s/152s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
                                                                      ^
  tests/testthat/test-utils.R:27:52: style: Opening curly braces should never go on their own line and should always be followed by a new line.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                     ^
  tests/testthat/test-utils.R:27:67: style: Closing curly-braces should always be on their own line, unless it's followed by an else.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                                    ^


  testthat results ================================================================
  OK: 17 SKIPPED: 0 FAILED: 1
  1. Failure: package Style (@test-zzz-lintr.R#5)

  Error: testthat unit tests failed
  Execution halted
```

## KernelKnn (1.0.5)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>
Bug reports: https://github.com/mlampros/KernelKnn/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘KernelKnn’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/KernelKnn.Rcheck/00install.out’ for details.
```

## lawn (0.3.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>
Bug reports: http://www.github.com/ropensci/lawn/issues

1 error  | 0 warnings | 0 notes

```
checking tests ... ERROR
  Running ‘test-all.R’
Running the tests in ‘tests/test-all.R’ failed.
Last 13 lines of output:
  Actual value: "c++ exception (unknown reason)"


  2. Failure: lawn_centroid fails correctly (@test-centroid.R#50) ----------------
  error$message does not match "Unexpected number".
  Actual value: "c++ exception (unknown reason)"


  testthat results ================================================================
  OK: 805 SKIPPED: 0 FAILED: 2
  1. Failure: lawn_centroid fails correctly (@test-centroid.R#47)
  2. Failure: lawn_centroid fails correctly (@test-centroid.R#50)

  Error: testthat unit tests failed
  Execution halted
```

## mlrMBO (1.1.0)
Maintainer: Jakob Richter <code@jakob-r.de>
Bug reports: https://github.com/mlr-org/mlrMBO/issues

0 errors | 1 warning  | 0 notes

```
checking re-building of vignette outputs ... WARNING
Error in re-building vignettes:
  ...
Warning in (function (filename = if (onefile) "Rplots.svg" else "Rplot%03d.svg",  :
  unable to load shared object '/Library/Frameworks/R.framework/Resources/library/grDevices/libs//cairo.so':
  dlopen(/Library/Frameworks/R.framework/Resources/library/grDevices/libs//cairo.so, 6): Library not loaded: /opt/X11/lib/libfontconfig.1.dylib
  Referenced from: /Library/Frameworks/R.framework/Resources/library/grDevices/libs//cairo.so
  Reason: Incompatible library version: cairo.so requires version 11.0.0 or later, but libfontconfig.1.dylib provides version 10.0.0
Warning in (function (filename = if (onefile) "Rplots.svg" else "Rplot%03d.svg",  :
  failed to load cairo DLL
Warning in (function (filename = if (onefile) "Rplots.svg" else "Rplot%03d.svg",  :
  failed to load cairo DLL
Warning in (function (filename = if (onefile) "Rplots.svg" else "Rplot%03d.svg",  :
  failed to load cairo DLL
Warning in (function (filename = if (onefile) "Rplots.svg" else "Rplot%03d.svg",  :
  failed to load cairo DLL
pandoc: Could not fetch mlrMBO_files/figure-html/cosine_fun-1.svg
mlrMBO_files/figure-html/cosine_fun-1.svg: openBinaryFile: does not exist (No such file or directory)
Error: processing vignette 'mlrMBO.Rmd' failed with diagnostics:
pandoc document conversion failed with error 67
Execution halted

```

## nandb (0.2.0)
Maintainer: Rory Nolan <rorynoolan@gmail.com>
Bug reports: https://github.com/rorynolan/nandb/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available:
  ‘autothresholdr’ ‘BiocParallel’ ‘EBImage’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## OpenImageR (1.0.6)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>
Bug reports: https://github.com/mlampros/OpenImageR/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘OpenImageR’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/OpenImageR.Rcheck/00install.out’ for details.
```

## RSQLServer (0.3.0)
Maintainer: Imanuel Costigan <i.costigan@me.com>
Bug reports: https://github.com/imanuelcostigan/RSQLServer/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required and available but unsuitable version: ‘dplyr’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## textTinyR (1.0.7)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>
Bug reports: https://github.com/mlampros/textTinyR/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘textTinyR’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/textTinyR.Rcheck/00install.out’ for details.
```

## valr (0.3.0)
Maintainer: Jay Hesselberth <jay.hesselberth@gmail.com>
Bug reports: https://github.com/rnabioco/valr/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Package required and available but unsuitable version: ‘dplyr’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## Wmisc (0.3.2)
Maintainer: Markus S. Wamser <r-wmisc@devel.wamser.eu>
Bug reports: https://github.com/wamserma/R-Wmisc/issues

1 error  | 0 warnings | 2 notes

```
checking tests ... ERROR
  Running ‘testthat.R’ [55s/63s]
Running the tests in ‘tests/testthat.R’ failed.
Last 13 lines of output:
                                                                      ^
  tests/testthat/test-utils.R:27:52: style: Opening curly braces should never go on their own line and should always be followed by a new line.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                     ^
  tests/testthat/test-utils.R:27:67: style: Closing curly-braces should always be on their own line, unless it's followed by an else.
    with_mock(`covr:::system_output` = function(...) { " test_hash" }, {
                                                                    ^


  testthat results ================================================================
  OK: 147 SKIPPED: 0 FAILED: 1
  1. Failure: Package has good style (no lints) (@test-lints.R#5)

  Error: testthat unit tests failed
  Execution halted

checking installed package size ... NOTE
  installed size is  5.2Mb
  sub-directories of 1Mb or more:
    doc   5.0Mb

checking compiled code ... NOTE
File ‘Wmisc/libs/Wmisc.so’:
  Found no calls to: ‘R_registerRoutines’, ‘R_useDynamicSymbols’

It is good practice to register native routines and to disable symbol
search.

See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
```

