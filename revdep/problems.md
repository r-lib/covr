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
4 packages with problems

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

## textreuse (0.1.4)
Maintainer: Lincoln Mullen <lincoln@lincolnmullen.com>  
Bug reports: https://github.com/ropensci/textreuse/issues

1 error  | 0 warnings | 0 notes

```
checking whether package ‘textreuse’ can be installed ... ERROR
Installation failed.
See ‘/Users/jhester/Dropbox/projects/covr/revdep/checks/textreuse.Rcheck/00install.out’ for details.
```

