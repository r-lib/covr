# Setup

## Platform

|setting  |value                                  |
|:--------|:--------------------------------------|
|version  |R version 3.3.2 RC (2016-10-26 r71594) |
|system   |x86_64, darwin13.4.0                   |
|ui       |X11                                    |
|language |(EN)                                   |
|collate  |en_US.UTF-8                            |
|tz       |America/New_York                       |
|date     |2016-12-30                             |

## Packages

|package     |*  |version    |date       |source                           |
|:-----------|:--|:----------|:----------|:--------------------------------|
|covr        |   |2.2.1      |2016-12-30 |local (jimhester/covr@NA)        |
|crayon      |   |1.3.2      |2016-06-28 |cran (@1.3.2)                    |
|devtools    |*  |1.12.0     |2016-06-24 |cran (@1.12.0)                   |
|DT          |   |0.2        |2016-08-09 |cran (@0.2)                      |
|htmltools   |   |0.3.5      |2016-03-21 |cran (@0.3.5)                    |
|htmlwidgets |   |0.8        |2016-11-09 |cran (@0.8)                      |
|httr        |   |1.2.1      |2016-07-03 |cran (@1.2.1)                    |
|jsonlite    |   |1.1        |2016-09-14 |cran (@1.1)                      |
|knitr       |   |1.15.1     |2016-11-22 |cran (@1.15.1)                   |
|memoise     |   |1.0.0      |2016-01-29 |cran (@1.0.0)                    |
|R6          |   |2.2.0      |2016-10-05 |cran (@2.2.0)                    |
|rex         |   |1.1.1      |2016-03-11 |cran (@1.1.1)                    |
|rmarkdown   |   |1.3        |2016-12-21 |cran (@1.3)                      |
|rstudioapi  |   |0.6        |2016-06-27 |cran (@0.6)                      |
|shiny       |   |0.14.2     |2016-11-01 |cran (@0.14.2)                   |
|testthat    |   |1.0.2.9000 |2016-12-30 |Github (hadley/testthat@3b2f225) |
|withr       |   |1.0.2      |2016-06-20 |cran (@1.0.2)                    |
|xml2        |   |1.0.0      |2016-06-24 |cran (@1.0.0)                    |

# Check results
151 packages

## ABCoptim (0.14.0)
Maintainer: George Vega Yon <g.vegayon@gmail.com>

0 errors | 0 warnings | 0 notes

## aemo (0.2.0)
Maintainer: Imanuel Costigan <i.costigan@me.com>

0 errors | 0 warnings | 0 notes

## after (1.0.0)
Maintainer: Gábor Csárdi <csardi.gabor@gmail.com>  
Bug reports: https://github.com/gaborcsardi/after/issues

0 errors | 0 warnings | 0 notes

## ALA4R (1.5.3)
Maintainer: Ben Raymond <ben_ala@untan.gl>

0 errors | 0 warnings | 0 notes

## analogsea (0.5.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/sckott/analogsea/issues

0 errors | 0 warnings | 0 notes

## ashr (2.0.5)
Maintainer: Peter Carbonetto <pcarbo@uchicago.edu>

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘REBayes’ ‘Rmosek’
```

## betalink (2.2.1)
Maintainer: Timothee Poisot <tim@poisotlab.io>

0 errors | 0 warnings | 1 note 

```
checking DESCRIPTION meta-information ... NOTE
Checking should be performed on sources prepared by ‘R CMD build’.
```

## bgmfiles (0.0.6)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: 
        https://github.com/AustralianAntarcticDivision/bgmfiles/issues/

0 errors | 0 warnings | 0 notes

## binman (0.0.7)
Maintainer: John Harrison <johndharrison0@gmail.com>  
Bug reports: https://github.com/johndharrison/binman/issues

0 errors | 0 warnings | 0 notes

## blob (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/blob/issues

0 errors | 0 warnings | 0 notes

## bold (0.3.5)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/bold/issues

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘sangerseqR’
```

## broom (0.4.1)
Maintainer: David Robinson <admiral.david@gmail.com>  
Bug reports: http://github.com/dgrtwo/broom/issues

1 error  | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘broom-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: survfit_tidiers
> ### Title: tidy survival curve fits
> ### Aliases: glance.survfit survfit_tidiers tidy.survfit
> 
> ### ** Examples
... 43 lines ...
+         do(glance(survfit(coxph(Surv(time, status) ~ age + sex, .))))
+     
+     glances
+     
+     qplot(glances$median, binwidth = 15)
+     quantile(glances$median, c(.025, .975))
+ }
Error in data.frame(..., check.names = FALSE) : 
  arguments imply differing number of rows: 237, 0, 711
Calls: tidy -> tidy.survfit -> cbind -> cbind -> data.frame
Execution halted

checking Rd cross-references ... NOTE
Package unavailable to check Rd xrefs: ‘akima’
```

## brranching (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/brranching/issues

0 errors | 0 warnings | 0 notes

## BTYDplus (1.0.1)
Maintainer: Michael Platzer <michael.platzer@gmail.com>  
Bug reports: https://github.com/mplatzer/BTYDplus/issues

0 errors | 0 warnings | 0 notes

## callr (1.0.0)
Maintainer: Gábor Csárdi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/callr/issues

0 errors | 0 warnings | 0 notes

## cellranger (1.1.0)
Maintainer: Jennifer Bryan <jenny@stat.ubc.ca>  
Bug reports: https://github.com/rsheets/cellranger/issues

0 errors | 0 warnings | 0 notes

## ClusterR (1.0.3)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>  
Bug reports: https://github.com/mlampros/ClusterR/issues

0 errors | 0 warnings | 0 notes

## colorplaner (0.1.3)
Maintainer: William Murphy <william.murphy.rd@gmail.com>  
Bug reports: https://github.com/wmurphyrd/colorplaner/issues

0 errors | 0 warnings | 0 notes

## crul (0.1.6)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/crul/issues

0 errors | 0 warnings | 0 notes

## cvequality (0.1.1)
Maintainer: Ben Marwick <benmarwick@gmail.com>

0 errors | 0 warnings | 0 notes

## d3r (0.6.0)
Maintainer: Kent Russell <kent.russell@timelyportfolio.com>  
Bug reports: https://github.com/timelyportfolio/d3r/issues

1 error  | 0 warnings | 1 note 

```
checking examples ... ERROR
Running examples in ‘d3r-Ex.R’ failed
The error most likely occurred in:

> base::assign(".ptime", proc.time(), pos = "CheckExEnv")
> ### Name: d3_nest
> ### Title: Convert a 'data.frame' to a 'd3.js' Hierarchy
> ### Aliases: d3_nest
> 
> ### ** Examples
... 31 lines ...
# A tibble: 1 × 2
          children    name
            <list>   <chr>
1 <tibble [4 × 3]> titanic
> 
> # see the structure with listviewer
> tit_tb %>%
+   listviewer::jsonedit()
Error in loadNamespace(name) : there is no package called ‘listviewer’
Calls: %>% ... tryCatch -> tryCatchList -> tryCatchOne -> <Anonymous>
Execution halted

checking package dependencies ... NOTE
Package suggested but not available for checking: ‘listviewer’

Packages which this enhances but not available for checking:
  ‘partykit’ ‘treemap’
```

## DataExplorer (0.3.0)
Maintainer: Boxuan Cui <boxuancui@gmail.com>  
Bug reports: https://github.com/boxuancui/DataExplorer/issues

0 errors | 0 warnings | 0 notes

## datastepr (0.0.2)
Maintainer: Brandon Taylor <brandon.taylor221@gmail.com>  
Bug reports: https://github.com/bramtayl/datastepr/issues

0 errors | 0 warnings | 0 notes

## DBI (0.5-1)
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

## debugme (1.0.1)
Maintainer: Gábor Csárdi <csardi.gabor@gmail.com>  
Bug reports: https://github.com/gaborcsardi/debugme/issues

0 errors | 0 warnings | 0 notes

## dendextend (1.3.0)
Maintainer: Tal Galili <tal.galili@gmail.com>  
Bug reports: https://github.com/talgalili/dendextend/issues

0 errors | 0 warnings | 2 notes

```
checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘ggdendro’ ‘labeltodendro’ ‘dendroextras’

checking Rd cross-references ... NOTE
Packages unavailable to check Rd xrefs: ‘WGCNA’, ‘dendroextras’, ‘moduleColor’, ‘distory’, ‘ggdendro’
```

## descriptr (0.1.0)
Maintainer: Aravind Hebbali <hebbali.aravind@gmail.com>  
Bug reports: https://github.com/rsquaredacademy/descriptr/issues

0 errors | 0 warnings | 0 notes

## devtools (1.12.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/devtools/issues

0 errors | 0 warnings | 0 notes

## diffobj (0.1.6)
Maintainer: Brodie Gaslam <brodie.gaslam@yahoo.com>  
Bug reports: https://github.com/brodieG/diffobj/issues

0 errors | 0 warnings | 0 notes

## discgolf (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/sckott/discgolf/issues

0 errors | 0 warnings | 0 notes

## dplyr (0.5.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/dplyr/issues

0 errors | 0 warnings | 0 notes

## dtplyr (0.0.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/dtplyr/issues

0 errors | 0 warnings | 0 notes

## elastic (0.7.8)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/elastic/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.4Mb
  sub-directories of 1Mb or more:
    examples   4.6Mb
```

## EpiModel (1.2.8)
Maintainer: Samuel Jenness <samuel.m.jenness@emory.edu>  
Bug reports: https://github.com/statnet/EpiModel/issues

0 errors | 0 warnings | 0 notes

## errorlocate (0.1.2)
Maintainer: Edwin de Jonge <edwindjonge@gmail.com>

0 errors | 0 warnings | 0 notes

## fauxpas (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropenscilabs/fauxpas/issues

0 errors | 0 warnings | 0 notes

## fiery (0.2.1)
Maintainer: Thomas Lin Pedersen <thomasp85@gmail.com>  
Bug reports: https://github.com/thomasp85/fiery/issues

0 errors | 0 warnings | 0 notes

## finch (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/finch/issues

0 errors | 0 warnings | 0 notes

## FLightR (0.4.5)
Maintainer: Eldar Rakhimberdiev <eldar@nioz.nl>  
Bug reports: http://github.com/eldarrak/FLightR/issues

1 error  | 0 warnings | 0 notes

```
checking package dependencies ... ERROR
Packages required but not available: ‘ggsn’ ‘GeoLight’

See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
manual.
```

## forcats (0.1.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/forcats/issues

0 errors | 0 warnings | 0 notes

## formattable (0.2.0.1)
Maintainer: Kun Ren <ken@renkun.me>  
Bug reports: https://github.com/renkun-ken/formattable/issues

0 errors | 0 warnings | 0 notes

## fuzzyjoin (0.1.2)
Maintainer: David Robinson <drobinson@stackoverflow.com>

0 errors | 0 warnings | 0 notes

## GeneralTree (0.0.1)
Maintainer: Anton Bossenbroek <anton.bossenbroek@me.com>

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.2Mb
  sub-directories of 1Mb or more:
    doc   4.9Mb
```

## geojson (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/geojson/issues

0 errors | 0 warnings | 0 notes

## geojsonlint (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropenscilabs/geojsonlint/issues

0 errors | 0 warnings | 0 notes

## getlandsat (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropenscilabs/getlandsat/issues

0 errors | 0 warnings | 0 notes

## ggplot2 (2.2.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/tidyverse/ggplot2/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.2Mb
  sub-directories of 1Mb or more:
    R     2.2Mb
    doc   1.5Mb
```

## goldi (1.0.0)
Maintainer: Christopher B. Cole <chris.c.1221@gmail.com>  
Bug reports: https://github.com/Chris1221/goldi/issues

0 errors | 0 warnings | 0 notes

## googleAnalyticsR (0.3.0)
Maintainer: Mark Edmondson <m@sunholo.com>  
Bug reports: 
        https://github.com/MarkEdmondson1234/googleAnalyticsR/issues

0 errors | 0 warnings | 0 notes

## googleAuthR (0.4.0)
Maintainer: Mark Edmondson <m@sunholo.com>  
Bug reports: https://github.com/MarkEdmondson1234/googleAuthR/issues

0 errors | 0 warnings | 0 notes

## googleCloudStorageR (0.2.0)
Maintainer: Mark Edmondson <r@sunholo.com>  
Bug reports: https://github.com/cloudyr/googleCloudStorageR/issues

0 errors | 0 warnings | 0 notes

## googleComputeEngineR (0.1.0)
Maintainer: Mark Edmondson <r@sunholo.com>  
Bug reports: https://github.com/cloudyr/googleComputeEngineR/issues

0 errors | 0 warnings | 0 notes

## googlesheets (0.2.1)
Maintainer: Jennifer Bryan <jenny@stat.ubc.ca>  
Bug reports: https://github.com/jennybc/googlesheets/issues

0 errors | 0 warnings | 0 notes

## gtable (0.2.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>

0 errors | 0 warnings | 0 notes

## HARtools (0.0.5)
Maintainer: John Harrison <johndharrison0@gmail.com>  
Bug reports: https://github.com/johndharrison/HARtools/issues

0 errors | 0 warnings | 0 notes

## haven (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/haven/issues

0 errors | 0 warnings | 1 note 

```
checking for GNU extensions in Makefiles ... NOTE
GNU make is a SystemRequirements.
```

## incidence (1.1.0)
Maintainer: Thibaut Jombart <thibautjombart@gmail.com>  
Bug reports: http://github.com/reconhub/incidence/issues

0 errors | 0 warnings | 0 notes

## isdparser (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropenscilabs/isdparser/issues

0 errors | 0 warnings | 0 notes

## jqr (0.2.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/jqr/issues

0 errors | 0 warnings | 0 notes

## KernelKnn (1.0.3)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>  
Bug reports: https://github.com/mlampros/KernelKnn/issues

0 errors | 0 warnings | 0 notes

## largeVis (0.1.10.2)
Maintainer: Amos Elberg <amos.elberg@gmail.com>  
Bug reports: https://github.com/elbamos/largeVis/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  6.5Mb
  sub-directories of 1Mb or more:
    doc            1.0Mb
    libs           1.2Mb
    testdata       1.9Mb
    vignettedata   2.0Mb
```

## lawn (0.3.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/lawn/issues

0 errors | 0 warnings | 0 notes

## lazyeval (0.2.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>

0 errors | 0 warnings | 0 notes

## lexRankr (0.3.0)
Maintainer: Adam Spannbauer <spannbaueradam@gmail.com>

0 errors | 0 warnings | 0 notes

## lubridate (1.6.0)
Maintainer: Vitalie Spinu <spinuvit@gmail.com>  
Bug reports: https://github.com/hadley/lubridate/issues

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Packages which this enhances but not available for checking:
  ‘timeDate’ ‘its’ ‘tis’ ‘timeSeries’ ‘fts’ ‘tseries’
```

## mapr (0.3.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/mapr/issues

0 errors | 0 warnings | 0 notes

## mcparallelDo (1.1.0)
Maintainer: Russell S. Pierce <russell.s.pierce@gmail.com>  
Bug reports: https://github.com/drknexus/mcparallelDo/issues

0 errors | 0 warnings | 0 notes

## modelr (0.1.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/modelr/issues

0 errors | 0 warnings | 0 notes

## Momocs (1.1.0)
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

## mregions (0.1.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropenscilabs/mregions/issues

0 errors | 0 warnings | 0 notes

## naptime (1.2.0)
Maintainer: Russell Pierce <russell.s.pierce@gmail.com>  
Bug reports: https://github.com/drknexus/naptime/issues

0 errors | 0 warnings | 0 notes

## natserv (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/natserv/issues

0 errors | 0 warnings | 0 notes

## netdiffuseR (1.17.0)
Maintainer: George Vega Yon <g.vegayon@gmail.com>  
Bug reports: https://github.com/USCCANA/netdiffuseR/issues

0 errors | 0 warnings | 0 notes

## normalr (0.0.1)
Maintainer: Kevin Chang <k.chang@auckland.ac.nz>  
Bug reports: https://github.com/kcha193/normalr/issues

0 errors | 0 warnings | 0 notes

## oai (0.2.2)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/oai/issues

0 errors | 0 warnings | 0 notes

## openadds (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/sckott/openadds/issues

0 errors | 0 warnings | 0 notes

## OpenImageR (1.0.2)
Maintainer: Lampros Mouselimis <mouselimislampros@gmail.com>  
Bug reports: https://github.com/mlampros/OpenImageR/issues

0 errors | 0 warnings | 0 notes

## optiRum (0.37.3)
Maintainer: Stephanie Locke <stephanie.g.locke@gmail.com>  
Bug reports: https://github.com/stephlocke/optiRum/issues

0 errors | 0 warnings | 0 notes

## originr (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/originr/issues

0 errors | 0 warnings | 0 notes

## outbreaks (1.1.0)
Maintainer: Finlay Campbell <f.campbell15@imperial.ac.uk>  
Bug reports: https://github.com/reconhub/outbreaks/issues

0 errors | 0 warnings | 0 notes

## palr (0.0.6)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/AustralianAntarcticDivision/palr/issues

0 errors | 0 warnings | 0 notes

## pangaear (0.2.4)
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

## primefactr (0.1.0)
Maintainer: Florian Privé <florian.prive.21@gmail.com>  
Bug reports: https://github.com/privefl/primefactr/issues

0 errors | 0 warnings | 0 notes

## productplots (0.1.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/productplots/issues

0 errors | 0 warnings | 0 notes

## prof.tree (0.1.0)
Maintainer: Artem Kelvtsov <a.a.klevtsov@gmail.com>  
Bug reports: https://github.com/artemklevtsov/prof.tree/issues

0 errors | 0 warnings | 0 notes

## proto (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/proto/issues

0 errors | 0 warnings | 0 notes

## ptstem (0.0.2)
Maintainer: Daniel Falbel <dfalbel@gmail.com>

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.3Mb
  sub-directories of 1Mb or more:
    dict   5.1Mb
```

## purrr (0.2.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/purrr/issues

0 errors | 0 warnings | 0 notes

## qwraps2 (0.2.4)
Maintainer: Peter DeWitt <dewittpe@gmail.com>

0 errors | 0 warnings | 0 notes

## radiant.basics (0.6.0)
Maintainer: Vincent Nijs <radiant@rady.ucsd.edu>  
Bug reports: https://github.com/radiant-rstats/radiant.basics/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.2Mb
  sub-directories of 1Mb or more:
    app   4.5Mb
```

## radiant.data (0.6.0)
Maintainer: Vincent Nijs <radiant@rady.ucsd.edu>  
Bug reports: https://github.com/radiant-rstats/radiant.data/issues

0 errors | 0 warnings | 0 notes

## radiant.model (0.6.0)
Maintainer: Vincent Nijs <radiant@rady.ucsd.edu>  
Bug reports: https://github.com/radiant-rstats/radiant.model/issues

0 errors | 0 warnings | 0 notes

## radiant.multivariate (0.6.0)
Maintainer: Vincent Nijs <radiant@rady.ucsd.edu>  
Bug reports: 
        https://github.com/radiant-rstats/radiant.multivariate/issues

0 errors | 0 warnings | 0 notes

## radiant (0.6.0)
Maintainer: Vincent Nijs <radiant@rady.ucsd.edu>  
Bug reports: https://github.com/radiant-rstats/radiant/issues

0 errors | 0 warnings | 0 notes

## ratelimitr (0.3.7)
Maintainer: Tarak Shah <tarak_shah@berkeley.edu>  
Bug reports: https://github.com/tarakc02/ratelimitr/issues

0 errors | 0 warnings | 0 notes

## rbgm (0.0.4)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/AustralianAntarcticDivision/rbgm/issues/

0 errors | 0 warnings | 0 notes

## rbhl (0.3.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rbhl/issues

0 errors | 0 warnings | 0 notes

## rbison (0.5.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rbison/issues

0 errors | 0 warnings | 0 notes

## rcrossref (0.6.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rcrossref/issues

0 errors | 0 warnings | 0 notes

## rdpla (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rdpla/issues

0 errors | 0 warnings | 0 notes

## readr (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/readr/issues

0 errors | 0 warnings | 0 notes

## rematch (1.0.1)
Maintainer: Gabor Csardi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/rematch/issues

0 errors | 0 warnings | 0 notes

## rgeospatialquality (0.3.2)
Maintainer: Javier Otegui <javier.otegui@gmail.com>  
Bug reports: https://github.com/ropenscilabs/rgeospatialquality/issues

0 errors | 0 warnings | 0 notes

## rintrojs (0.1.2)
Maintainer: Carl Ganz <carlganz@gmail.com>  
Bug reports: https://github.com/carlganz/rintrojs/issues

0 errors | 0 warnings | 0 notes

## ritis (0.5.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/ritis/issues

0 errors | 0 warnings | 0 notes

## rnoaa (0.6.6)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rnoaa/issues

0 errors | 0 warnings | 0 notes

## rnpn (0.1.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>

0 errors | 0 warnings | 0 notes

## rodham (0.0.2)
Maintainer: John Coene <jcoenep@gmail.com>

0 errors | 0 warnings | 0 notes

## rplos (0.6.4)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rplos/issues

0 errors | 0 warnings | 0 notes

## rrecsys (0.9.5.4)
Maintainer: Ludovik Çoba <lcoba@unishk.edu.al>  
Bug reports: https://github.com/ludovikcoba/rrecsys/issues

0 errors | 0 warnings | 0 notes

## rredlist (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropenscilabs/rredlist/issues

0 errors | 0 warnings | 0 notes

## RSauceLabs (0.1.6)
Maintainer: John Harrison <johndharrison0@gmail.com>  
Bug reports: https://github.com/johndharrison/RSauceLabs/issues

0 errors | 0 warnings | 0 notes

## RSelenium (1.6.2)
Maintainer: John Harrison <johndharrison0@gmail.com>  
Bug reports: http://github.com/ropensci/RSelenium/issues

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘Rcompression’
```

## rslp (0.1.0)
Maintainer: Daniel Falbel <dfalbel@gmail.com>

0 errors | 0 warnings | 0 notes

## rsnps (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rsnps/issues

0 errors | 0 warnings | 0 notes

## rstack (1.0.0)
Maintainer: Gábor Csárdi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/rstack/issues

0 errors | 0 warnings | 0 notes

## rstantools (1.1.0)
Maintainer: Jonah Gabry <jsg2201@columbia.edu>  
Bug reports: https://github.com/stan-dev/rstantools/issues

0 errors | 0 warnings | 0 notes

## rvertnet (0.5.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/rvertnet/issues

0 errors | 0 warnings | 0 notes

## rvest (0.3.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/rvest/issues

0 errors | 0 warnings | 0 notes

## rvg (0.1.1)
Maintainer: David Gohel <david.gohel@ardata.fr>  
Bug reports: https://github.com/davidgohel/rvg/issues

0 errors | 0 warnings | 0 notes

## scales (0.4.1)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/scales/issues

0 errors | 0 warnings | 0 notes

## seleniumPipes (0.3.7)
Maintainer: John Harrison <johndharrison0@gmail.com>  
Bug reports: https://github.com/johndharrison/seleniumPipes/issues

0 errors | 0 warnings | 0 notes

## sigmoid (0.2.0)
Maintainer: Bastiaan Quast <bquast@gmail.com>

0 errors | 0 warnings | 0 notes

## simmer.plot (0.1.4)
Maintainer: Iñaki Ucar <i.ucar86@gmail.com>  
Bug reports: https://github.com/r-simmer/simmer.plot/issues

0 errors | 0 warnings | 0 notes

## simmer (3.6.0)
Maintainer: Iñaki Ucar <i.ucar86@gmail.com>  
Bug reports: https://github.com/r-simmer/simmer/issues

0 errors | 0 warnings | 0 notes

## sofa (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/sofa/issues

0 errors | 0 warnings | 0 notes

## solrium (0.4.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/solrium/issues

0 errors | 0 warnings | 0 notes

## SpaDES (1.3.1)
Maintainer: Alex M Chubaty <alexander.chubaty@canada.ca>  
Bug reports: https://github.com/PredictiveEcology/SpaDES/issues

0 errors | 0 warnings | 2 notes

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘fastshp’

checking installed package size ... NOTE
  installed size is  6.5Mb
  sub-directories of 1Mb or more:
    R     3.5Mb
    doc   2.1Mb
```

## spbabel (0.4.5)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/mdsumner/spbabel/issues

0 errors | 0 warnings | 0 notes

## spdplyr (0.1.2)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/mdsumner/spdplyr/issues

0 errors | 0 warnings | 0 notes

## spex (0.1.0)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/mdsumner/spex/issues

0 errors | 0 warnings | 0 notes

## spocc (0.6.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/spocc/issues

0 errors | 0 warnings | 0 notes

## stringr (1.1.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/stringr/issues

0 errors | 0 warnings | 0 notes

## svglite (1.2.0)
Maintainer: Lionel Henry <lionel@rstudio.com>  
Bug reports: https://github.com/hadley/svglite/issues

0 errors | 0 warnings | 0 notes

## taxize (0.8.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: https://github.com/ropensci/taxize/issues

0 errors | 0 warnings | 0 notes

## testthat (1.0.2)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/testthat/issues

0 errors | 0 warnings | 0 notes

## text2vec (0.4.0)
Maintainer: Dmitriy Selivanov <selivanov.dmitriy@gmail.com>  
Bug reports: https://github.com/dselivanov/text2vec/issues

0 errors | 0 warnings | 2 notes

```
checking installed package size ... NOTE
  installed size is  7.2Mb
  sub-directories of 1Mb or more:
    data   2.7Mb
    doc    3.5Mb

checking for GNU extensions in Makefiles ... NOTE
GNU make is a SystemRequirements.
```

## textreuse (0.1.4)
Maintainer: Lincoln Mullen <lincoln@lincolnmullen.com>  
Bug reports: https://github.com/ropensci/textreuse/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘textreuse’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/textreuse.Rcheck/00install.out’ for details.
```

## tidyr (0.6.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/tidyr/issues

0 errors | 0 warnings | 0 notes

## tokenizers (0.1.4)
Maintainer: Lincoln Mullen <lincoln@lincolnmullen.com>  
Bug reports: https://github.com/ropensci/tokenizers/issues

0 errors | 0 warnings | 0 notes

## toxboot (0.1.1)
Maintainer: Eric D. Watt <eric@ericdwatt.com>  
Bug reports: https://github.com/ericwatt/toxboot/issues

0 errors | 0 warnings | 1 note 

```
checking package dependencies ... NOTE
Package suggested but not available for checking: ‘rmongodb’
```

## traits (0.2.0)
Maintainer: Scott Chamberlain <myrmecocystus@gmail.com>  
Bug reports: http://www.github.com/ropensci/traits/issues

0 errors | 0 warnings | 0 notes

## trip (1.5.0)
Maintainer: Michael D. Sumner <mdsumner@gmail.com>  
Bug reports: https://github.com/mdsumner/trip/issues

0 errors | 0 warnings | 0 notes

## units (0.4-1)
Maintainer: Edzer Pebesma <edzer.pebesma@uni-muenster.de>  
Bug reports: https://github.com/edzer/units/issues/

0 errors | 0 warnings | 0 notes

## valr (0.1.1)
Maintainer: Jay Hesselberth <jay.hesselberth@gmail.com>  
Bug reports: https://github.com/jayhesselberth/valr/issues

0 errors | 0 warnings | 0 notes

## vembedr (0.1.1)
Maintainer: Ian Lyttle <ian.lyttle@schneider-electric.com>  
Bug reports: https://github.com/ijlyttle/vembedr/issues

0 errors | 0 warnings | 0 notes

## Wmisc (0.3.1)
Maintainer: Markus S. Wamser <r-wmisc@devel.wamser.eu>  
Bug reports: https://github.com/wamserma/R-Wmisc/issues

0 errors | 0 warnings | 1 note 

```
checking installed package size ... NOTE
  installed size is  5.2Mb
  sub-directories of 1Mb or more:
    doc   5.0Mb
```

## xml2 (1.0.0)
Maintainer: Hadley Wickham <hadley@rstudio.com>  
Bug reports: https://github.com/hadley/xml2/issues/

0 errors | 0 warnings | 1 note 

```
checking compilation flags in Makevars ... NOTE
Package has both ‘src/Makevars.in’ and ‘src/Makevars’.
Installation with --no-configure' is unlikely to work.  If you intended
‘src/Makevars’ to be used on Windows, rename it to ‘src/Makevars.win’
otherwise remove it.  If ‘configure’ created ‘src/Makevars’, you need a
‘cleanup’ script.
```

## xmlparsedata (1.0.1)
Maintainer: Gábor Csárdi <gcsardi@mango-solutions.com>  
Bug reports: https://github.com/MangoTheCat/xmlparsedata/issues

0 errors | 0 warnings | 0 notes

