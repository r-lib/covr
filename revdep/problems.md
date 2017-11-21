# ALA4R

Version: 1.5.6

## In both

*   R CMD check timed out


# analogsea

Version: 0.5.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:

      testthat results ================================================================
      OK: 21 SKIPPED: 0 FAILED: 9
      1. Error: returns expected output for sizes endpoint (@test-do_GET.R#7)
      2. Error: returns expected output for regions endpoint (@test-do_GET.R#16)
      3. Failure: incorrect input to what param returns NULL (@test-domains.R#7)
      4. Failure: fails well with non-existent droplet (@test-droplet.R#11)
      5. Failure: fails well with non-existent droplet (@test-image.R#11)
      6. Error: returns expected output for public images (@test-images.R#7)
      7. Error: works with type parameter (@test-images.R#25)
      8. Error: returns expected output (@test-regions.R#7)
      9. Error: returns expected output (@test-sizes.R#7)

      Error: testthat unit tests failed
      Execution halted
    ```

# antaresViz

Version: 0.11

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘magrittr’ ‘tibble’
      All declared Imports should be used.
    ```

# ashr

Version: 2.0.5

## In both

*   checking package dependencies ... NOTE
    ```
    Packages which this enhances but not available for checking:
      ‘REBayes’ ‘Rmosek’
    ```

# betalink

Version: 2.2.1

## In both

*   checking DESCRIPTION meta-information ... NOTE
    ```
    Checking should be performed on sources prepared by ‘R CMD build’.
    ```

# bigstatsr

Version: 0.2.2

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      'dimnames' applied to non-array
      1: sparseSVM::sparseSVM(X2, y.factor, alpha = alpha, lambda.min = lambda.min, penalty.factor = m) at testthat/test-spSVM.R:32

      2. Error: equality with sparseSVM with only half the data (@test-spSVM.R#68) ---
      'dimnames' applied to non-array
      1: sparseSVM::sparseSVM(X2[ind, ], y.factor[ind], alpha = alpha, lambda.min = lambda.min,
             penalty.factor = m) at testthat/test-spSVM.R:68

      testthat results ================================================================
      OK: 1627 SKIPPED: 0 FAILED: 2
      1. Error: equality with sparseSVM with all data (@test-spSVM.R#32)
      2. Error: equality with sparseSVM with only half the data (@test-spSVM.R#68)

      Error: testthat unit tests failed
      Execution halted
    ```

# bikedata

Version: 0.0.4

## In both

*   checking re-building of vignette outputs ... WARNING
    ```
    ...
     8: handle(ev <- withCallingHandlers(withVisible(eval(expr, envir,     enclos)), warning = wHandler, error = eHandler, message = mHandler))
     9: timing_fn(handle(ev <- withCallingHandlers(withVisible(eval(expr,     envir, enclos)), warning = wHandler, error = eHandler, message = mHandler)))
    10: evaluate_call(expr, parsed$src[[i]], envir = envir, enclos = enclos,     debug = debug, last = i == length(out), use_try = stop_on_error !=         2L, keep_warning = keep_warning, keep_message = keep_message,     output_handler = output_handler, include_timing = include_timing)
    11: evaluate(code, envir = env, new_device = FALSE, keep_warning = !isFALSE(options$warning),     keep_message = !isFALSE(options$message), stop_on_error = if (options$error &&         options$include) 0L else 2L, output_handler = knit_handlers(options$render,         options))
    12: in_dir(input_dir(), evaluate(code, envir = env, new_device = FALSE,     keep_warning = !isFALSE(options$warning), keep_message = !isFALSE(options$message),     stop_on_error = if (options$error && options$include) 0L else 2L,     output_handler = knit_handlers(options$render, options)))
    13: block_exec(params)
    14: call_block(x)
    15: process_group.block(group)
    16: process_group(group)
    17: withCallingHandlers(if (tangle) process_tangle(group) else process_group(group),     error = function(e) {        setwd(wd)        cat(res, sep = "\n", file = output %n% "")        message("Quitting from lines ", paste(current_lines(i),             collapse = "-"), " (", knit_concord$get("infile"),             ") ")    })
    18: process_file(text, output)
    19: knitr::knit(knit_input, knit_output, envir = envir, quiet = quiet,     encoding = encoding)
    20: rmarkdown::render(file, encoding = encoding, quiet = quiet, envir = globalenv())
    21: vweave_rmarkdown(...)
    22: engine$weave(file, quiet = quiet, encoding = enc)
    23: doTryCatch(return(expr), name, parentenv, handler)
    24: tryCatchOne(expr, names, parentenv, handlers[[1L]])
    25: tryCatchList(expr, classes, parentenv, handlers)
    26: tryCatch({    engine$weave(file, quiet = quiet, encoding = enc)    setwd(startdir)    find_vignette_product(name, by = "weave", engine = engine)}, error = function(e) {    stop(gettextf("processing vignette '%s' failed with diagnostics:\n%s",         file, conditionMessage(e)), domain = NA, call. = FALSE)})
    27: buildVignettes(dir = ".../revdep/checks/bikedata/new/bikedata.Rcheck/vign_test/bikedata")
    An irrecoverable exception occurred. R is aborting now ...
    ```

# biolink

Version: 0.1.2

## In both

*   checking tests ...
    ```
     ERROR
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

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘utils’
      All declared Imports should be used.
    ```

# blastula

Version: 0.1

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘rJava’
      All declared Imports should be used.
    ```

# bomrang

Version: 0.0.8

## In both

*   R CMD check timed out


# breathtestcore

Version: 0.4.0

## In both

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘breathteststan’
    ```

# broom

Version: 0.4.2

## In both

*   checking examples ... ERROR
    ```
    ...
    +   f2 <- Finance[1:300, "hml"] - rf
    +   f3 <- Finance[1:300, "smb"] - rf
    +   h <- cbind(f1, f2, f3)
    +   res2 <- gmm(z ~ f1 + f2 + f3, x = h)
    +
    +   td2 <- tidy(res2, conf.int = TRUE)
    +   td2
    +
    +   # coefficient plot
    +   td2 %>%
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
    ```

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Complete output:
      > library(testthat)
      > test_check("broom")
      Loading required package: broom
      Error in lahman_df() : could not find function "lahman_df"
      Calls: test_check ... with_reporter -> force -> source_file -> eval -> eval -> tbl
      testthat results ================================================================
      OK: 621 SKIPPED: 0 FAILED: 0
      Execution halted
    ```

# bsplus

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘methods’
      All declared Imports should be used.
    ```

# BTYDplus

Version: 1.0.1

## In both

*   checking tests ...
    ```
     ERROR
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
      OK: 187 SKIPPED: 2 FAILED: 1
      1. Failure: Package Style (@test-style.R#5)

      Error: testthat unit tests failed
      Execution halted
    ```

# canvasXpress

Version: 1.17.4

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘magrittr’
      All declared Imports should be used.
    ```

# ccafs

Version: 0.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      one or more files don't exist
      1: cc_data_read(res[1]) at testthat/test-cc_data_read.R:11
      2: cc_data_read.ccafs_files(res[1]) at .../revdep/checks/ccafs/new/ccafs.Rcheck/00_pkg_src/ccafs/R/cc_data_read.R:43
      3: cc_data_read(unclass(x), unreadable) at .../revdep/checks/ccafs/new/ccafs.Rcheck/00_pkg_src/ccafs/R/cc_data_read.R:53
      4: cc_data_read.character(unclass(x), unreadable) at .../revdep/checks/ccafs/new/ccafs.Rcheck/00_pkg_src/ccafs/R/cc_data_read.R:43
      5: stop("one or more files don't exist", call. = FALSE) at .../revdep/checks/ccafs/new/ccafs.Rcheck/00_pkg_src/ccafs/R/cc_data_read.R:59

      testthat results ================================================================
      OK: 30 SKIPPED: 0 FAILED: 3
      1. Failure: cc_data_fetch works (@test-cc_data_fetch.R#13)
      2. Failure: cc_data_fetch works (@test-cc_data_fetch.R#14)
      3. Error: cc_data_read works (@test-cc_data_read.R#11)

      Error: testthat unit tests failed
      Execution halted
    ```

# ClusterR

Version: 1.0.8

## In both

*   checking whether package ‘ClusterR’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/ClusterR/new/ClusterR.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘ClusterR’ ...
** package ‘ClusterR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c kmeans_miniBatchKmeans_GMM_Medoids.cpp -o kmeans_miniBatchKmeans_GMM_Medoids.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c utils_rcpp.cpp -o utils_rcpp.o
clang: error: unsupported option '-fopenmp'
clangclang: error: : error: unsupported option '-fopenmp'unsupported option '-fopenmp'

make: *** [RcppExports.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [utils_rcpp.o] Error 1
make: *** [kmeans_miniBatchKmeans_GMM_Medoids.o] Error 1
ERROR: compilation failed for package ‘ClusterR’
* removing ‘.../revdep/checks/ClusterR/new/ClusterR.Rcheck/ClusterR’

```
### CRAN

```
* installing *source* package ‘ClusterR’ ...
** package ‘ClusterR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c kmeans_miniBatchKmeans_GMM_Medoids.cpp -o kmeans_miniBatchKmeans_GMM_Medoids.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/ClusterR/Rcpp/include" -I".../revdep/library/ClusterR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c utils_rcpp.cpp -o utils_rcpp.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [utils_rcpp.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [kmeans_miniBatchKmeans_GMM_Medoids.o] Error 1
make: *** [RcppExports.o] Error 1
ERROR: compilation failed for package ‘ClusterR’
* removing ‘.../revdep/checks/ClusterR/old/ClusterR.Rcheck/ClusterR’

```
# congressbr

Version: 0.1.1

## In both

*   checking re-building of vignette outputs ... WARNING
    ```
    Error in re-building vignettes:
      ...
    Loading required package: dplyr

    Attaching package: 'dplyr'

    The following objects are masked from 'package:stats':

        filter, lag

    The following objects are masked from 'package:base':

        intersect, setdiff, setequal, union

    Quitting from lines 29-30 (senate.Rmd)
    Error: processing vignette 'senate.Rmd' failed with diagnostics:
    Timeout was reached: Connection timed out after 10008 milliseconds
    Execution halted
    ```

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 1 marked UTF-8 string
    ```

# curatedMetagenomicData

Version: 1.2.2

## In both

*   R CMD check timed out


*   checking package dependencies ... NOTE
    ```
    Depends: includes the non-default packages:
      ‘dplyr’ ‘phyloseq’ ‘Biobase’ ‘ExperimentHub’ ‘AnnotationHub’
      ‘magrittr’
    Adding so many packages to the search path is excessive and importing
    selectively is preferable.
    ```

*   checking installed package size ... NOTE
    ```
      installed size is  8.6Mb
      sub-directories of 1Mb or more:
        help   7.9Mb
    ```

*   checking DESCRIPTION meta-information ... NOTE
    ```
    Package listed in more than one of Depends, Imports, Suggests, Enhances:
      ‘BiocInstaller’
    A package should be listed in only one of these fields.
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘BiocInstaller’
      All declared Imports should be used.
    ```

*   checking R code for possible problems ... NOTE
    ```
    ExpressionSet2MRexperiment: no visible global function definition for
      ‘AnnotatedDataFrame’
      (.../revdep/checks/curatedMetagenomicData/new/curatedMetagenomicData.Rcheck/00_pkg_src/curatedMetagenomicData/R/ExpressionSet2MRexperiment.R:45)
    ExpressionSet2MRexperiment: no visible global function definition for
      ‘phenoData’
      (.../revdep/checks/curatedMetagenomicData/new/curatedMetagenomicData.Rcheck/00_pkg_src/curatedMetagenomicData/R/ExpressionSet2MRexperiment.R:46-47)
    curatedMetagenomicData : <anonymous>: no visible global function
      definition for ‘exprs<-’
      (.../revdep/checks/curatedMetagenomicData/new/curatedMetagenomicData.Rcheck/00_pkg_src/curatedMetagenomicData/R/curatedMetagenomicData.R:57-58)
    Undefined global functions or variables:
      AnnotatedDataFrame exprs<- phenoData
    ```

*   checking Rd files ... NOTE
    ```
    prepare_Rd: HMP_2012.Rd:540-542: Dropping empty section \seealso
    prepare_Rd: KarlssonFH_2013.Rd:90-92: Dropping empty section \seealso
    prepare_Rd: LeChatelierE_2013.Rd:86-88: Dropping empty section \seealso
    prepare_Rd: LomanNJ_2013_Hi.Rd:82-84: Dropping empty section \seealso
    prepare_Rd: LomanNJ_2013_Mi.Rd:82-84: Dropping empty section \seealso
    prepare_Rd: NielsenHB_2014.Rd:94-96: Dropping empty section \seealso
    prepare_Rd: Obregon_TitoAJ_2015.Rd:94-96: Dropping empty section \seealso
    prepare_Rd: OhJ_2014.Rd:86-88: Dropping empty section \seealso
    prepare_Rd: QinJ_2012.Rd:106-108: Dropping empty section \seealso
    prepare_Rd: QinN_2014.Rd:94-96: Dropping empty section \seealso
    prepare_Rd: RampelliS_2015.Rd:90-92: Dropping empty section \seealso
    prepare_Rd: TettAJ_2016.Rd:184-186: Dropping empty section \seealso
    prepare_Rd: ZellerG_2014.Rd:94-96: Dropping empty section \seealso
    ```

# darksky

Version: 1.3.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      + }
      1. Error: the API call works (@test-darksky.R#6) -------------------------------
      Please set env var DARKSKY_API_KEY to your Dark Sky API key
      1: get_current_forecast(43.2672, -70.8617) at testthat/test-darksky.R:6
      2: sprintf("https://api.darksky.net/forecast/%s/%s,%s", darksky_api_key(), latitude,
             longitude) at .../revdep/checks/darksky/new/darksky.Rcheck/00_pkg_src/darksky/R/get-current-forecast.r:53
      3: darksky_api_key()
      4: stop("Please set env var DARKSKY_API_KEY to your Dark Sky API key", call. = FALSE) at .../revdep/checks/darksky/new/darksky.Rcheck/00_pkg_src/darksky/R/api-key.r:23

      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 1
      1. Error: the API call works (@test-darksky.R#6)

      Error: testthat unit tests failed
      Execution halted
    ```

# dbplyr

Version: 1.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘tibble’
      All declared Imports should be used.
    ```

# dendextend

Version: 1.5.2

## In both

*   checking package dependencies ... NOTE
    ```
    Packages which this enhances but not available for checking:
      ‘ggdendro’ ‘labeltodendro’ ‘dendroextras’ ‘Hmisc’
    ```

*   checking Rd cross-references ... NOTE
    ```
    Packages unavailable to check Rd xrefs: ‘WGCNA’, ‘dendroextras’, ‘moduleColor’, ‘distory’, ‘phangorn’, ‘ggdendro’, ‘zoo’
    ```

# DepthProc

Version: 2.0.2

## In both

*   checking whether package ‘DepthProc’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/DepthProc/new/DepthProc.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘DepthProc’ ...
** package ‘DepthProc’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c Depth.cpp -o Depth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationEstimators.cpp -o LocationEstimators.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationScaleDepth.cpp -o LocationScaleDepth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationScaleDepthCPP.cpp -o LocationScaleDepthCPP.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c RobCovLib.cpp -o RobCovLib.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c TukeyDepth.cpp -o TukeyDepth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c Utils.cpp -o Utils.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [TukeyDepth.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [RobCovLib.o] Error 1
make: *** [RcppExports.o] Error 1
make: *** [LocationScaleDepth.o] Error 1
make: *** [LocationEstimators.o] Error 1
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [Utils.o] Error 1
make: *** [LocationScaleDepthCPP.o] Error 1
clang: error: unsupported option '-fopenmp'
make: *** [Depth.o] Error 1
ERROR: compilation failed for package ‘DepthProc’
* removing ‘.../revdep/checks/DepthProc/new/DepthProc.Rcheck/DepthProc’

```
### CRAN

```
* installing *source* package ‘DepthProc’ ...
** package ‘DepthProc’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c Depth.cpp -o Depth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationEstimators.cpp -o LocationEstimators.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationScaleDepth.cpp -o LocationScaleDepth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c LocationScaleDepthCPP.cpp -o LocationScaleDepthCPP.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c RobCovLib.cpp -o RobCovLib.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c TukeyDepth.cpp -o TukeyDepth.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -fopenmp -I".../revdep/library/DepthProc/Rcpp/include" -I".../revdep/library/DepthProc/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2 -c Utils.cpp -o Utils.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [Utils.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [TukeyDepth.o] Error 1
make: *** [RobCovLib.o] Error 1
make: *** [RcppExports.o] Error 1
make: *** [LocationScaleDepthCPP.o] Error 1
make: *** [LocationScaleDepth.o] Error 1
make: *** [LocationEstimators.o] Error 1
make: *** [Depth.o] Error 1
ERROR: compilation failed for package ‘DepthProc’
* removing ‘.../revdep/checks/DepthProc/old/DepthProc.Rcheck/DepthProc’

```
# detrendr

Version: 0.1.0

## In both

*   checking for GNU extensions in Makefiles ... NOTE
    ```
    GNU make is a SystemRequirements.
    ```

# devtools

Version: 1.13.3

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-that.R’ failed.
    Last 13 lines of output:
      > library(testthat)
      > test_check("devtools")
      Loading required package: devtools
      1. Failure: Github repos with submodules are identified correctly (@test-github.r#82)
      github_has_remotes(github_remote("armstrtw/rzmq")) not equal to TRUE.
      1 element mismatch



      testthat results ================================================================
      OK: 433 SKIPPED: 0 FAILED: 1
      1. Failure: Github repos with submodules are identified correctly (@test-github.r#82)

      Error: testthat unit tests failed
      Execution halted
    ```

# DiagrammeR

Version: 0.9.2

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  6.4Mb
      sub-directories of 1Mb or more:
        R             1.9Mb
        htmlwidgets   3.0Mb
    ```

# diceR

Version: 0.2.0

## In both

*   checking whether package ‘diceR’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/diceR/new/diceR.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘diceR’ ...
** package ‘diceR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c connectivity_matrix.cpp -o connectivity_matrix.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c indicator_matrix.cpp -o indicator_matrix.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [RcppExports.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [connectivity_matrix.o] Error 1
make: *** [indicator_matrix.o] Error 1
ERROR: compilation failed for package ‘diceR’
* removing ‘.../revdep/checks/diceR/new/diceR.Rcheck/diceR’

```
### CRAN

```
* installing *source* package ‘diceR’ ...
** package ‘diceR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c connectivity_matrix.cpp -o connectivity_matrix.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG  -I".../revdep/library/diceR/Rcpp/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c indicator_matrix.cpp -o indicator_matrix.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [RcppExports.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [connectivity_matrix.o] Error 1
make: *** [indicator_matrix.o] Error 1
ERROR: compilation failed for package ‘diceR’
* removing ‘.../revdep/checks/diceR/old/diceR.Rcheck/diceR’

```
# discgolf

Version: 0.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 6 SKIPPED: 0 FAILED: 17
      1. Error: badges works as expected (@test-badges.R#6)
      2. Error: badges_user works as expected (@test-badges.R#23)
      3. Failure: badges_user fails well with no input (@test-badges.R#41)
      4. Failure: fails well with non-existent user (@test-badges.R#53)
      5. Error: categories works as expected (@test-categories.R#6)
      6. Error: category works as expected (@test-categories.R#20)
      7. Error: category_latest_topics works as expected (@test-categories.R#34)
      8. Failure: fails well with no input (@test-categories.R#48)
      9. Failure: fails well with no input (@test-categories.R#50)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# document

Version: 2.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      .../revdep/checks/document/new/document.Rcheck
      .../revdep/library/covr/new
      .../revdep/library/document
      /Library/Frameworks/R.framework/Versions/3.4/Resources/library
      Sys.info:
      Jamess-MacBook-Pro-2.local
      Darwin Kernel Version 16.7.0: Thu Jun 15 17:36:27 PDT 2017; root:xnu-3789.70.16~2/RELEASE_X86_64
      Path: /var/folders/dt/r5s12t392tb5sk181j3gs4zw0000gn/T//RtmpwhEMrx/document_4dca51f8a1b4/mini.mal
      ###
      Error in check_package(package_directory = package_directory, working_directory = working_directory,  :
        R CMD check failed, read the above log and fix.
      Calls: test_check ... source_file -> eval -> eval -> document -> check_package -> throw
      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 0
      Execution halted
    ```

# docuSignr

Version: 0.0.3

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      Sys.getenv("docuSign_password") != "" isn't true.


      3. Failure: Environmental vars exist (@test-1-login.R#7) -----------------------
      Sys.getenv("docuSign_integrator_key") != "" isn't true.


      testthat results ================================================================
      OK: 0 SKIPPED: 15 FAILED: 3
      1. Failure: Environmental vars exist (@test-1-login.R#5)
      2. Failure: Environmental vars exist (@test-1-login.R#6)
      3. Failure: Environmental vars exist (@test-1-login.R#7)

      Error: testthat unit tests failed
      Execution halted
    ```

# dplyr

Version: 0.7.4

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 4 marked UTF-8 strings
    ```

# easyml

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘corrplot’ ‘scorer’
      All declared Imports should be used.
    ```

# EML

Version: 1.0.3

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  7.7Mb
      sub-directories of 1Mb or more:
        R     1.3Mb
        xsd   5.4Mb
    ```

# enigma

Version: 0.3.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      4: stop("need an API key for the Enigma API")

      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 8
      1. Error: enigma_data column selection works correctly (@test-enigma_data.R#8)
      2. Error: enigma_data works correctly for sorting data (@test-enigma_data.R#20)
      3. Error: enigma_data works correctly to get data subset (@test-enigma_data.R#33)
      4. Error: enigma_metadata basic functionality works (@test-enigma_metadata.R#10)
      5. Error: enigma_metadata parent node data differs from child node data (@test-enigma_metadata.R#21)
      6. Error: enigma_stats works correctly with varchar column (@test-enigma_stats.R#9)
      7. Error: enigma_stats works correctly with numeric column (@test-enigma_stats.R#20)
      8. Error: enigma_stats works correctly with date column (@test-enigma_stats.R#32)

      Error: testthat unit tests failed
      Execution halted
    ```

# epicontacts

Version: 1.0.1

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 146 SKIPPED: 0 FAILED: 14
      1. Failure: graph3D produces json that is not null (@test_graph3D.R#12)
      2. Failure: graph3D errors as expected on bad annotation and group specification (@test_graph3D.R#38)
      3. Failure: graph3D errors as expected on bad annotation and group specification (@test_graph3D.R#41)
      4. Failure: graph3D errors as expected on bad annotation and group specification (@test_graph3D.R#44)
      5. Failure: graph3D errors as expected on bad annotation and group specification (@test_graph3D.R#47)
      6. Failure: graph3D object includes annotation (@test_graph3D.R#61)
      7. Failure: Printing objects works (@test_print.epicontacts.R#11)
      8. Failure: Plotting groups as color (@test_vis_epicontacts.R#24)
      9. Failure: Plotting groups as color (@test_vis_epicontacts.R#25)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘colorspace’
      All declared Imports should be used.
    ```

# fauxpas

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘whisker’
      All declared Imports should be used.
    ```

# fiery

Version: 1.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘desc’
      All declared Imports should be used.
    ```

# finch

Version: 0.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:

      2. Failure: dwca_get - works with a url - read=FALSE (@test-dwca_get.R#49) -----
      Names of aa$data ('') don't match 'core', 'extension'


      trying URL 'http://ipt.jbrj.gov.br/jbrj/archive.do?r=redlist_2013_taxons&v=3.12'
      downloaded 105 KB

      testthat results ================================================================
      OK: 50 SKIPPED: 0 FAILED: 2
      1. Failure: dwca_get - works with a url - read=FALSE (@test-dwca_get.R#48)
      2. Failure: dwca_get - works with a url - read=FALSE (@test-dwca_get.R#49)

      Error: testthat unit tests failed
      Execution halted
    ```

# FLightR

Version: 0.4.6

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘rgdal’
      All declared Imports should be used.
    ```

# foghorn

Version: 0.4.4

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 49 SKIPPED: 0 FAILED: 10
      1.  Failure: output of summary cran results (@test-foghorn.R#176)
      2.  Failure: output of summary cran results (@test-foghorn.R#178)
      3.  Failure: output of summary cran results (@test-foghorn.R#189)
      4.  Failure: output of summary cran results (@test-foghorn.R#201)
      5.  Failure: output of summary cran results (@test-foghorn.R#213)
      6.  Failure: output of summary cran results (@test-foghorn.R#226)
      7.  Failure: output of summary cran results (@test-foghorn.R#233)
      8.  Failure: output of summary cran results (@test-foghorn.R#239)
      9.  Failure: output of show cran results (@test-foghorn.R#264)
      10. Failure: output of show cran results (@test-foghorn.R#266)

      Error: testthat unit tests failed
      Execution halted
    ```

# FRK

Version: 0.1.6

## Newly broken

*   R CMD check timed out


## In both

*   checking package dependencies ... NOTE
    ```
    Package suggested but not available for checking: ‘INLA’

    Package which this enhances but not available for checking: ‘dggrids’
    ```

*   checking installed package size ... NOTE
    ```
      installed size is  7.6Mb
      sub-directories of 1Mb or more:
        data   4.8Mb
        doc    1.6Mb
    ```

# gastempt

Version: 0.4.01

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  7.0Mb
      sub-directories of 1Mb or more:
        libs   6.5Mb
    ```

# geex

Version: 1.0.3

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘rootSolve’
      All declared Imports should be used.
    ```

# geofacet

Version: 0.1.5

## In both

*   checking tests ...
    ```
     ERROR
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

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 79 marked UTF-8 strings
    ```

# getlandsat

Version: 0.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      length(gg) is not strictly more than 0. Difference: 0


      testthat results ================================================================
      OK: 48 SKIPPED: 0 FAILED: 7
      1. Failure: lsat_cache_list works (@test-cache.R#28)
      2. Failure: lsat_cache_details works (@test-cache.R#48)
      3. Failure: lsat_cache_details works (@test-cache.R#54)
      4. Error: lsat_cache_details works (@test-cache.R#55)
      5. Failure: lsat_cache_delete works (@test-cache.R#66)
      6. Error: lsat_cache_delete works (@test-cache.R#67)
      7. Failure: lsat_cache_delete_all works (@test-cache.R#80)

      Error: testthat unit tests failed
      Execution halted
    ```

# GGIR

Version: 1.5-12

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.5Mb
      sub-directories of 1Mb or more:
        R      1.6Mb
        data   2.4Mb
        doc    1.2Mb
    ```

# ggplot2

Version: 2.2.1

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.2Mb
      sub-directories of 1Mb or more:
        R     2.2Mb
        doc   1.5Mb
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘reshape2’
      All declared Imports should be used.
    ```

# ggridges

Version: 0.4.1

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 6242 marked UTF-8 strings
    ```

# gh

Version: 1.0.1

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
        API rate limit exceeded for 173.88.174.51. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)
      1: tryCatch(gh("/missing", .token = tt()), http_error_404 = identity) at testthat/test-mock-error.R:19
      2: tryCatchList(expr, classes, parentenv, handlers)
      3: tryCatchOne(expr, names, parentenv, handlers[[1L]])
      4: doTryCatch(return(expr), name, parentenv, handler)
      5: gh("/missing", .token = tt())
      6: gh_process_response(raw) at .../revdep/checks/gh/new/gh.Rcheck/00_pkg_src/gh/R/package.R:121

      testthat results ================================================================
      OK: 24 SKIPPED: 3 FAILED: 2
      1. Failure: errors return a github_error object (@test-mock-error.R#11)
      2. Error: can catch a given status directly (@test-mock-error.R#19)

      Error: testthat unit tests failed
      Execution halted
    ```

# glassdoor

Version: 0.7.6

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘xml2’
      All declared Imports should be used.
    ```

# googleAuthR

Version: 0.6.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# googleCloudStorageR

Version: 0.3.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 3 SKIPPED: 0 FAILED: 36
      1. Error: We can login (@test.R#11)
      2. Error: We can list buckets (@test.R#25)
      3. Error: We can get a bucket (@test.R#32)
      4. Error: We can create a bucket (@test.R#41)
      5. Error: We can upload to the new bucket (@test.R#50)
      6. Error: We can delete upload to the new bucket (@test.R#59)
      7. Error: We can make a bucket with lifecycle and versioning set (@test.R#72)
      8. Error: We can upload a file (@test.R#92)
      9. Error: We can upload a data.frame (@test.R#100)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# googleComputeEngineR

Version: 0.2.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 5 SKIPPED: 0 FAILED: 46
      1. Error: We can see a project resource (@test_aa_auth.R#16)
      2. Error: We can set auto project (@test_aa_auth.R#26)
      3. Error: We can get auto project (@test_aa_auth.R#37)
      4. Error: We can list networks (@test_aa_auth.R#70)
      5. Error: We can get a network (@test_aa_auth.R#79)
      6. Error: We can make a container VM (@test_bb_create_vm.R#7)
      7. Error: We can make a VM with metadata (@test_bb_create_vm.R#24)
      8. Error: We can make a template VM (@test_bb_create_vm.R#41)
      9. Error: We can make a VM with custom disk size (@test_bb_create_vm.R#57)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# googlesheets

Version: 0.2.2

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(googlesheets)
      >
      > if (identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
      +   test_check("googlesheets")
      + }
      Error: Cannot read token from alleged .rds file:
      googlesheets_token.rds
      testthat results ================================================================
      OK: 2 SKIPPED: 0 FAILED: 0
      Execution halted
    ```

*   checking re-building of vignette outputs ... WARNING
    ```
    Error in re-building vignettes:
      ...
    Quitting from lines 37-41 (basic-usage.Rmd)
    Error: processing vignette 'basic-usage.Rmd' failed with diagnostics:
    Cannot read token from alleged .rds file:
    ../tests/testthat/googlesheets_token.rds
    Execution halted
    ```

# GSODR

Version: 1.1.0

## Newly broken

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
             skip = skip, comment = comment, n_max = n_max, guess_max = guess_max, progress = progress)
      4: read_connection(file)
      5: open(con, "rb")
      6: open.connection(con, "rb")

      testthat results ================================================================
      OK: 50 SKIPPED: 0 FAILED: 4
      1. Error: .download_files properly works, subsetting for country and
                  agroclimatology works and .process_gz returns a data table (@test-process_gz.R#23)
      2. Error: reformat_GSOD file_list parameter reformats data properly (@test-reformat_GSOD.R#15)
      3. Error: Timeout options are reset on update_station_list() exit (@test-update_station_list.R#6)
      4. Error: update_station_list() downloads and imports proper file (@test-update_station_list.R#13)

      Error: testthat unit tests failed
      Execution halted
    ```

# hansard

Version: 0.5.5

## Newly fixed

*   R CMD check timed out


## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat-ep.R’ failed.
    Last 13 lines of output:
             verbose = TRUE) at testthat/test_epetition.R:19
      2: jsonlite::fromJSON(paste0(baseurl, status_query, sig_query, dates, extra_args), flatten = TRUE) at .../revdep/checks/hansard/new/hansard.Rcheck/00_pkg_src/hansard/R/epetition_tibble.R:53
      3: fromJSON_string(txt = txt, simplifyVector = simplifyVector, simplifyDataFrame = simplifyDataFrame,
             simplifyMatrix = simplifyMatrix, flatten = flatten, ...)
      4: parseJSON(txt, bigint_as_char)
      5: parse_con(txt, bigint_as_char)
      6: open(con, "rb")
      7: open.connection(con, "rb")

      testthat results ================================================================
      OK: 7 SKIPPED: 0 FAILED: 1
      1. Error: epetitions functions return expected format (@test_epetition.R#19)

      Error: testthat unit tests failed
      Execution halted
    ```

# haven

Version: 1.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘hms’
      All declared Imports should be used.
    ```

*   checking for GNU extensions in Makefiles ... NOTE
    ```
    GNU make is a SystemRequirements.
    ```

# heatmaply

Version: 0.12.1

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.1Mb
      sub-directories of 1Mb or more:
        doc   4.6Mb
    ```

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘d3heatmap’
    ```

# huxtable

Version: 1.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
             message = handle_message))
      4: withCallingHandlers(withVisible(code), warning = handle_warning, message = handle_message)
      5: withVisible(code)
      6: rmarkdown::render("table-tester-2.Rmd", quiet = TRUE, output_format = "pdf_document")
      7: convert(output_file, run_citeproc)
      8: pandoc_convert(utf8_input, pandoc_to, output_format$pandoc$from, output, citeproc,
             output_format$pandoc$args, !quiet)
      9: stop("pandoc document conversion failed with error ", result, call. = FALSE)

      testthat results ================================================================
      OK: 290 SKIPPED: 48 FAILED: 1
      1. Error: table-tester-2.Rmd renders without errors in LaTeX (@test-with-pandoc.R#27)

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘xtable’
    ```

# incidence

Version: 1.2.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 215 SKIPPED: 0 FAILED: 16
      1. Failure: fit_optim_split (@test-fit.R#41)
      2. Failure: fit_optim_split (@test-fit.R#42)
      3. Failure: plot for incidence object (@test-plot.R#36)
      4. Failure: plot for incidence object (@test-plot.R#37)
      5. Failure: plot for incidence object (@test-plot.R#38)
      6. Failure: plot for incidence object (@test-plot.R#39)
      7. Failure: plot for incidence object (@test-plot.R#40)
      8. Failure: plot for incidence object (@test-plot.R#41)
      9. Failure: plot for incidence object (@test-plot.R#42)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# Inflation

Version: 0.1.0

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 151 marked UTF-8 strings
    ```

# KernelKnn

Version: 1.0.6

## In both

*   checking whether package ‘KernelKnn’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/KernelKnn/new/KernelKnn.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘KernelKnn’ ...
** package ‘KernelKnn’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c distance_metrics.cpp -o distance_metrics.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [RcppExports.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [distance_metrics.o] Error 1
ERROR: compilation failed for package ‘KernelKnn’
* removing ‘.../revdep/checks/KernelKnn/new/KernelKnn.Rcheck/KernelKnn’

```
### CRAN

```
* installing *source* package ‘KernelKnn’ ...
** package ‘KernelKnn’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c distance_metrics.cpp -o distance_metrics.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/KernelKnn/Rcpp/include" -I".../revdep/library/KernelKnn/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [distance_metrics.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [RcppExports.o] Error 1
ERROR: compilation failed for package ‘KernelKnn’
* removing ‘.../revdep/checks/KernelKnn/old/KernelKnn.Rcheck/KernelKnn’

```
# komadown

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘knitr’
      All declared Imports should be used.
    ```

# lingtypology

Version: 1.0.8

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 118 marked UTF-8 strings
    ```

# lubridate

Version: 1.7.0

## In both

*   checking package dependencies ... NOTE
    ```
    Packages which this enhances but not available for checking:
      ‘chron’ ‘fts’ ‘timeSeries’ ‘timeDate’ ‘tis’ ‘tseries’ ‘xts’ ‘zoo’
    ```

# mathpix

Version: 0.2.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      suppressWarnings(...) not equal to "$$\n p _ { i } ( \\theta ) = c _ { i } + \\frac { 1- c _ { i } } { 1+ e ^ { - a _ { i } \\theta - b _ { i } ) } } \n$$".
      1/1 mismatches
      x[1]: "$$\n p _ { i } ( \\theta ) = c _ { i } + \\frac { 1- c _ { i } } { 1+ e ^
      x[1]:  { - a _ { i } ( \\theta - b _ { i } ) } } \n$$"
      y[1]: "$$\n p _ { i } ( \\theta ) = c _ { i } + \\frac { 1- c _ { i } } { 1+ e ^
      y[1]:  { - a _ { i } \\theta - b _ { i } ) } } \n$$"


      testthat results ================================================================
      OK: 3 SKIPPED: 0 FAILED: 2
      1. Failure: Retrying image processing can be successful (@test_api.R#19)
      2. Failure: Retrying image processing can be successful (@test_api.R#21)

      Error: testthat unit tests failed
      Execution halted
    ```

# MFPCA

Version: 1.1

## In both

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘refund’
    ```

# mlrMBO

Version: 1.1.0

## In both

*   checking whether package ‘mlrMBO’ can be installed ... WARNING
    ```
    Found the following significant warnings:
      Warning: replacing previous import ‘BBmisc::isFALSE’ by ‘backports::isFALSE’ when loading ‘mlrMBO’
    See ‘.../revdep/checks/mlrMBO/new/mlrMBO.Rcheck/00install.out’ for details.
    ```

# modelr

Version: 0.1.1

## In both

*   checking Rd cross-references ... NOTE
    ```
    Packages unavailable to check Rd xrefs: ‘lme4’, ‘rstanarm’
    ```

# MODIStsp

Version: 1.3.3.1

## In both

*   checking package dependencies ... ERROR
    ```
    Package required but not available: ‘gWidgetsRGtk2’

    See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
    manual.
    ```

# Momocs

Version: 1.2.2

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  6.6Mb
      sub-directories of 1Mb or more:
        R      1.9Mb
        data   1.5Mb
        doc    2.3Mb
    ```

# natserv

Version: 0.1.4

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      3: cli$get(query = query) at .../revdep/checks/natserv/new/natserv.Rcheck/00_pkg_src/natserv/R/http.R:3
      4: private$make_url(self$url, self$handle, path, query)
      5: add_query(query, url)
      6: check_key(key)
      7: getOption("NatureServeKey", stop("You need an API key for NatureServe")) at .../revdep/checks/natserv/new/natserv.Rcheck/00_pkg_src/natserv/R/zzz.R:45
      8: stop("You need an API key for NatureServe")

      testthat results ================================================================
      OK: 14 SKIPPED: 0 FAILED: 3
      1. Error: ns_data works as expected (@test-ns_data.R#6)
      2. Error: ns_images works as expected (@test-ns_images.R#6)
      3. Error: ns_search works as expected (@test-ns_search.R#6)

      Error: testthat unit tests failed
      Execution halted
    ```

# odbc

Version: 1.1.3

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 4685 SKIPPED: 43 FAILED: 79
      1. Failure: DBItest[MySQL]: Result: send_query_trivial
      2. Failure: DBItest[MySQL]: Result: fetch_atomic
      3. Failure: DBItest[MySQL]: Result: fetch_one_row
      4. Failure: DBItest[MySQL]: Result: fetch_multi_row_single_column
      5. Failure: DBItest[MySQL]: Result: fetch_multi_row_multi_column
      6. Failure: DBItest[MySQL]: Result: fetch_n_progressive
      7. Failure: DBItest[MySQL]: Result: fetch_n_progressive
      8. Failure: DBItest[MySQL]: Result: fetch_n_progressive
      9. Failure: DBItest[MySQL]: Result: fetch_n_multi_row_inf
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# openadds

Version: 0.2.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      > library("testthat")
      > test_check("openadds")
      Loading required package: openadds
      1. Failure: oa_search works (@test-oa_search.R#39) -----------------------------
      length(dd$city) not equal to 2.
      1/1 mismatches
      [1] 3 - 2 == 1


      testthat results ================================================================
      OK: 47 SKIPPED: 0 FAILED: 1
      1. Failure: oa_search works (@test-oa_search.R#39)

      Error: testthat unit tests failed
      Execution halted
    ```

# OpenImageR

Version: 1.0.7

## In both

*   checking whether package ‘OpenImageR’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/OpenImageR/new/OpenImageR.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘OpenImageR’ ...
** package ‘OpenImageR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c dilation_erosion_rgb2gray.cpp -o dilation_erosion_rgb2gray.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c hog_features.cpp -o hog_features.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c image_hashing.cpp -o image_hashing.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c utils.cpp -o utils.o
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [dilation_erosion_rgb2gray.o] Error 1clang: error: unsupported option '-fopenmp'

make: *** Waiting for unfinished jobs....
make: *** [RcppExports.o] Error 1
make: *** [image_hashing.o] Error 1
clang: error: unsupported option '-fopenmp'
make: *** [utils.o] Error 1
clang: error: unsupported option '-fopenmp'
make: *** [hog_features.o] Error 1
ERROR: compilation failed for package ‘OpenImageR’
* removing ‘.../revdep/checks/OpenImageR/new/OpenImageR.Rcheck/OpenImageR’

```
### CRAN

```
* installing *source* package ‘OpenImageR’ ...
** package ‘OpenImageR’ successfully unpacked and MD5 sums checked
** libs
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c RcppExports.cpp -o RcppExports.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c dilation_erosion_rgb2gray.cpp -o dilation_erosion_rgb2gray.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c hog_features.cpp -o hog_features.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c image_hashing.cpp -o image_hashing.o
clang -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c init.c -o init.o
clang++ -std=gnu++11 -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include/ -I".../revdep/library/OpenImageR/Rcpp/include" -I".../revdep/library/OpenImageR/RcppArmadillo/include" -I/usr/local/include  -fopenmp -fPIC  -Wall -g -O2 -c utils.cpp -o utils.o
clang: error: unsupported option '-fopenmp'
clangclang: error: unsupported option '-fopenmp': error:
unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
clang: error: unsupported option '-fopenmp'
make: *** [dilation_erosion_rgb2gray.o] Error 1
make: *** Waiting for unfinished jobs....
make: *** [hog_features.o] Error 1
make: *** [RcppExports.o] Error 1
make: *** [image_hashing.o] Error 1
make: *** [utils.o] Error 1
ERROR: compilation failed for package ‘OpenImageR’
* removing ‘.../revdep/checks/OpenImageR/old/OpenImageR.Rcheck/OpenImageR’

```
# pacotest

Version: 0.2.2

## In both

*   R CMD check timed out


# pangaear

Version: 0.3.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      Actual value: "OAI-PMH errors: badArgument: from/until invalid: Text '3' could not be parsed at index 0"


      2. Failure: works well (@test-pg_data.R#16) ------------------------------------
      pg_cache_list() not equal to "10_1594_PANGAEA_807580.txt".
      Lengths differ: 2 vs 1


      testthat results ================================================================
      OK: 71 SKIPPED: 0 FAILED: 2
      1. Failure: fails well (@test-oai_functions.R#72)
      2. Failure: works well (@test-pg_data.R#16)

      Error: testthat unit tests failed
      Execution halted
    ```

# parlitools

Version: 0.2.1

## In both

*   checking package dependencies ... ERROR
    ```
    Package required but not available: ‘sf’

    See section ‘The DESCRIPTION file’ in the ‘Writing R Extensions’
    manual.
    ```

# petro.One

Version: 0.1.0

## Newly fixed

*   checking re-building of vignette outputs ... WARNING
    ```
    Error in re-building vignettes:
      ...
    Quitting from lines 68-78 (gather_thousand_papers_to_dataframe.Rmd)
    Error: processing vignette 'gather_thousand_papers_to_dataframe.Rmd' failed with diagnostics:
    HTTP error 500.
    Execution halted
    ```

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      1. Failure: all queries match expected values (@test_paper_count.R#134) --------
      get_papers_count(my_url) not equal to t$x.
      1/1 mismatches
      [1] 71 - 70 == 1


      Error: sum(df$value) not equal to 2275.
      1/1 mismatches
      [1] 2315 - 2275 == 40
      testthat results ================================================================
      OK: 63 SKIPPED: 0 FAILED: 1
      1. Failure: all queries match expected values (@test_paper_count.R#134)

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘Rgraphviz’ ‘cluster’ ‘graph’
      All declared Imports should be used.
    ```

# plyr

Version: 1.8.4

## In both

*   checking Rd \usage sections ... NOTE
    ```
    S3 methods shown with full name in documentation object 'rbind.fill':
      ‘rbind.fill’

    S3 methods shown with full name in documentation object 'rbind.fill.matrix':
      ‘rbind.fill.matrix’

    The \usage entries for S3 methods should use the \method markup and not
    their full name.
    See chapter ‘Writing R documentation files’ in the ‘Writing R
    Extensions’ manual.
    ```

# pmc

Version: 1.0.2

## In both

*   R CMD check timed out


# popEpi

Version: 0.4.3

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.2Mb
      sub-directories of 1Mb or more:
        R     1.9Mb
        doc   2.6Mb
    ```

# processx

Version: 2.0.0.1

## In both

*   checking compiled code ... NOTE
    ```
    File ‘processx/libs/processx.so’:
      Found non-API call to R: ‘R_new_custom_connection’

    Compiled code should not call non-API entry points in R.

    See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
    ```

# proustr

Version: 0.2.1

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 20105 marked UTF-8 strings
    ```

# psichomics

Version: 1.2.1

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.4Mb
      sub-directories of 1Mb or more:
        R     1.4Mb
        doc   3.3Mb
    ```

# psycho

Version: 0.0.2

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘rtf’ ‘tidyverse’
      All declared Imports should be used.
    ```

# ptstem

Version: 0.0.3

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.3Mb
      sub-directories of 1Mb or more:
        dict   5.1Mb
    ```

# purrrlyr

Version: 0.0.2

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘lazyeval’
      All declared Imports should be used.
    ```

# qwraps2

Version: 0.2.4

## In both

*   checking Rd \usage sections ... NOTE
    ```
    S3 methods shown with full name in documentation object 'summary_table':
      ‘cbind.qwraps2_summary_table’

    The \usage entries for S3 methods should use the \method markup and not
    their full name.
    See chapter ‘Writing R documentation files’ in the ‘Writing R
    Extensions’ manual.
    ```

# RcppXPtrUtils

Version: 0.1.0

## In both

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘inline’
    ```

# readr

Version: 1.1.1

## In both

*   checking compiled code ... NOTE
    ```
    File ‘readr/libs/readr.so’:
      Found non-API calls to R: ‘R_GetConnection’, ‘R_WriteConnection’

    Compiled code should not call non-API entry points in R.

    See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
    ```

# rjsonapi

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘crul’
      All declared Imports should be used.
    ```

# rmapzen

Version: 0.3.3

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      3: FUN(X[[i]], ...)
      4: vector_url(x = tile_coordinates$x, y = tile_coordinates$y, z = tile_coordinates$z,
             layers = "all", format = "json") at .../revdep/checks/rmapzen/new/rmapzen.Rcheck/00_pkg_src/rmapzen/R/vector-tiles.R:66
      5: structure(list(scheme = "https", hostname = "tile.mapzen.com", path = vector_path(layers,
             x, y, z, format), query = list(api_key = api_key)), class = "url") at .../revdep/checks/rmapzen/new/rmapzen.Rcheck/00_pkg_src/rmapzen/R/vector-tiles.R:133
      6: mz_key()
      7: stop("Set the MAPZEN_KEY environment variable") at .../revdep/checks/rmapzen/new/rmapzen.Rcheck/00_pkg_src/rmapzen/R/mz-key.R:3

      testthat results ================================================================
      OK: 199 SKIPPED: 0 FAILED: 2
      1. Error: single tiles can be pulled (@test-mz-vector-tiles.R#14)
      2. Error: multiple contiguous tiles can be pulled (@test-mz-vector-tiles.R#22)

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 31 marked UTF-8 strings
    ```

# rmonad

Version: 0.3.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# rnpn

Version: 0.1.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      bb$latitude inherits from `numeric` not `character`.


      testthat results ================================================================
      OK: 20 SKIPPED: 0 FAILED: 7
      1. Failure: npn_indsatstations works well (@test-npn_indsatstations.R#9)
      2. Failure: npn_indspatstations works well (@test-npn_indspatstations.R#9)
      3. Error: npn_obsspbyday works well (@test-npn_obsspbyday.R#6)
      4. Error: when no match, returns empty data.frame (@test-npn_obsspbyday.R#20)
      5. Failure: npn_stationsbystate works well (@test-npn_stationsbystate.R#11)
      6. Failure: npn_stationswithspp works well (@test-npn_stationswithspp.R#10)
      7. Failure: npn_stationswithspp works well (@test-npn_stationswithspp.R#15)

      Error: testthat unit tests failed
      Execution halted
    ```

# rodham

Version: 0.1.1

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘stringr’
      All declared Imports should be used.
    ```

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 59 marked UTF-8 strings
    ```

# routr

Version: 0.3.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘httpuv’ ‘utils’
      All declared Imports should be used.
    ```

# rplos

Version: 0.6.4

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 165 SKIPPED: 0 FAILED: 19
      1. Error: check_response catches no data found correctly (@test-check_response.R#20)
      2. Error: citations (@test-citations.R#15)
      3. Failure: facetplos (@test-facetplos.R#54)
      4. Error: facetplos (@test-facetplos.R#55)
      5. Error: full_text_urls - NA's on annotation DOIs (@test-fulltext.R#31)
      6. Error: plos_fulltext works (@test-fulltext.R#43)
      7. Error: highplos (@test-highplos.R#35)
      8. Error: journalnamekey returns the correct value (@test-journalnamekey.R#7)
      9. Error: journalnamekey returns the correct class (@test-journalnamekey.R#13)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking package dependencies ... NOTE
    ```
    Package which this enhances but not available for checking: ‘tm’
    ```

# RSauceLabs

Version: 0.1.6

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 38 SKIPPED: 0 FAILED: 26
      1. Failure: canGetRealTimeJobActivity (@test-acc_usage_methods_tests.R#6)
      2. Failure: canGetUserActivity (@test-acc_usage_methods_tests.R#11)
      3. Error: canGetAccountUsage (@test-acc_usage_methods_tests.R#17)
      4. Failure: canGetUser (@test-account_methods_tests.R#9)
      5. Failure: checkCanCreateSubAccount (@test-account_methods_tests.R#26)
      6. Failure: canGetUserConcurrency (@test-account_methods_tests.R#33)
      7. Failure: canGetSubUserConcurrency (@test-account_methods_tests.R#39)
      8. Failure: canGetSubUserConcurrency (@test-account_methods_tests.R#40)
      9. Failure: canGetListOfSubAccounts (@test-account_methods_tests.R#46)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

# RSelenium

Version: 1.7.1

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(RSelenium)
      >
      > if(Sys.getenv("NOT_CRAN") == "true"){
      +   test_check("RSelenium")
      + }
      Error in checkError(res) :
        Undefined error in httr call. httr output: Failed to connect to localhost port 4444: Connection refused
      Calls: test_check ... eval -> initFun -> <Anonymous> -> queryRD -> checkError
      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 0
      Execution halted
    ```

*   checking package dependencies ... NOTE
    ```
    Package suggested but not available for checking: ‘Rcompression’
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘binman’ ‘httr’
      All declared Imports should be used.
    ```

# rsnps

Version: 0.2.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      3. Failure: phenotypes returns the correct class (@test-phenotypes.R#11) -------
      as.character(suppressMessages(phenotypes(userid = 1))$user$name) not equal to "Bastian Greshake".
      1/1 mismatches
      x[1]: "Bastian Greshake Tzovaras"
      y[1]: "Bastian Greshake"


      testthat results ================================================================
      OK: 52 SKIPPED: 0 FAILED: 3
      1. Error: ld_search returns the correct data (@test-LDSearch.R#6)
      2. Error: ld_search fails well - one bad snp + other good ones (@test-LDSearch.R#31)
      3. Failure: phenotypes returns the correct class (@test-phenotypes.R#11)

      Error: testthat unit tests failed
      Execution halted
    ```

# scales

Version: 0.5.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘R6’
      All declared Imports should be used.
    ```

# seleniumPipes

Version: 0.3.7

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:

      The following objects are masked from 'package:testthat':

          equals, is_less_than, not

      Loading required package: whisker
      > if(Sys.getenv("NOT_CRAN") == "true"){
      +   test_check("seleniumPipes")
      + }
      Error in curl::curl_fetch_memory(url, handle = handle) :
        Failed to connect to localhost port 4444: Connection refused
      Calls: test_check ... request_fetch -> request_fetch.write_memory -> <Anonymous> -> .Call
      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 0
      Execution halted
    ```

# seqplots

Version: 1.14.1

## In both

*   checking installed package size ... NOTE
    ```
      installed size is 13.8Mb
      sub-directories of 1Mb or more:
        doc        2.6Mb
        seqplots  10.1Mb
    ```

*   checking foreign function calls ... NOTE
    ```
    Foreign function call to a different package:
      .Call("BWGFile_summary", ..., PACKAGE = "rtracklayer")
    See chapter ‘System and foreign language interfaces’ in the ‘Writing R
    Extensions’ manual.
    ```

*   checking R code for possible problems ... NOTE
    ```
    ...
    plotHeatmap,list: no visible global function definition for
      ‘as.dendrogram’
      (.../revdep/checks/seqplots/new/seqplots.Rcheck/00_pkg_src/seqplots/R/plotHeatmap.R:314-323)
    plotHeatmap,list: no visible global function definition for ‘title’
      (.../revdep/checks/seqplots/new/seqplots.Rcheck/00_pkg_src/seqplots/R/plotHeatmap.R:324)
    plotHeatmap,list: no visible global function definition for ‘par’
      (.../revdep/checks/seqplots/new/seqplots.Rcheck/00_pkg_src/seqplots/R/plotHeatmap.R:327)
    Undefined global functions or variables:
      Var1 Var2 abline adjustcolor approx as.dendrogram axis box
      capture.output colorRampPalette cutree dist hclust image kmeans
      layout lines mtext par plot.new qt rainbow rect rgb text title value
    Consider adding
      importFrom("grDevices", "adjustcolor", "colorRampPalette", "rainbow",
                 "rgb")
      importFrom("graphics", "abline", "axis", "box", "image", "layout",
                 "lines", "mtext", "par", "plot.new", "rect", "text",
                 "title")
      importFrom("stats", "approx", "as.dendrogram", "cutree", "dist",
                 "hclust", "kmeans", "qt")
      importFrom("utils", "capture.output")
    to your NAMESPACE file.
    ```

# sergeant

Version: 0.5.2

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      2: httr::POST(sprintf("%s/query.json", drill_server), encode = "json", body = list(queryType = "SQL",
             query = query)) at .../revdep/checks/sergeant/new/sergeant.Rcheck/00_pkg_src/sergeant/R/query.r:45
      3: request_perform(req, hu$handle$handle)
      4: request_fetch(req$output, req$url, handle)
      5: request_fetch.write_memory(req$output, req$url, handle)
      6: curl::curl_fetch_memory(url, handle = handle)

      testthat results ================================================================
      OK: 1 SKIPPED: 0 FAILED: 3
      1. Error: Core dbplyr ops work (@test-sergeant.R#12)
      2. Failure: REST API works (@test-sergeant.R#25)
      3. Error: REST API works (@test-sergeant.R#27)

      Error: testthat unit tests failed
      Execution halted
    ```

# sf

Version: 0.5-5

## In both

*   checking whether package ‘sf’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/sf/new/sf.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘sf’ ...
** package ‘sf’ successfully unpacked and MD5 sums checked
configure: loading site script /usr/local/share/config.site
configure: creating cache NONE/var/config.cache
./configure: line 1982: NONE/var/config.cache: No such file or directory
configure: CC: gcc
configure: CXX: clang++
checking for gdal-config... no
no
configure: error: gdal-config not found or not executable.
ERROR: configuration failed for package ‘sf’
* removing ‘.../revdep/checks/sf/new/sf.Rcheck/sf’

```
### CRAN

```
* installing *source* package ‘sf’ ...
** package ‘sf’ successfully unpacked and MD5 sums checked
configure: loading site script /usr/local/share/config.site
configure: creating cache NONE/var/config.cache
./configure: line 1982: NONE/var/config.cache: No such file or directory
configure: CC: gcc
configure: CXX: clang++
checking for gdal-config... no
no
configure: error: gdal-config not found or not executable.
ERROR: configuration failed for package ‘sf’
* removing ‘.../revdep/checks/sf/old/sf.Rcheck/sf’

```
# sicegar

Version: 0.2.2

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘dplyr’
      All declared Imports should be used.
    ```

# solrium

Version: 0.4.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
      testthat results ================================================================
      OK: 157 SKIPPED: 0 FAILED: 18
      1. Error: core_create works (@test-core_create.R#6)
      2. Error: ping works against (@test-ping.R#7)
      3. Error: ping gives raw data correctly (@test-ping.R#20)
      4. Error: ping fails well (@test-ping.R#31)
      5. Error: schema works against (@test-schema.R#7)
      6. Error: schema fails well (@test-schema.R#32)
      7. Error: solr_all works with HathiTrust (@test-solr_all.R#46)
      8. Error: solr_connect to local Solr server works (@test-solr_connect.R#19)
      9. Error: solr_connect works with a proxy (@test-solr_connect.R#33)
      1. ...

      Error: testthat unit tests failed
      Execution halted
    ```

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘XML’
    ```

# SpaDES.core

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘CircStats’ ‘RandomFields’ ‘grDevices’ ‘sp’
      All declared Imports should be used.
    ```

# splashr

Version: 0.4.0

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/test-all.R’ failed.
    Last 13 lines of output:
       /usr/bin/python
       /usr/local/bin/python3

      1: install_splash() at testthat/test-splash.R:25
      2: docker::docker$from_env at .../revdep/checks/splashr/new/splashr.Rcheck/00_pkg_src/splashr/R/docker-splash.r:13
      3: `$.python.builtin.module`(docker::docker, from_env) at .../revdep/checks/splashr/new/splashr.Rcheck/00_pkg_src/splashr/R/docker-splash.r:13
      4: py_resolve_module_proxy(x)
      5: stop(message, call. = FALSE)

      testthat results ================================================================
      OK: 0 SKIPPED: 0 FAILED: 1
      1. Error: we can do something (@test-splash.R#25)

      Error: testthat unit tests failed
      Execution halted
    ```

# sss

Version: 0.1-0

## In both

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘XML’
    ```

# statesRcontiguous

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘dplyr’ ‘magrittr’
      All declared Imports should be used.
    ```

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 34 marked UTF-8 strings
    ```

# stringr

Version: 1.2.0

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 3 marked UTF-8 strings
    ```

# text2vec

Version: 0.5.0

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  7.3Mb
      sub-directories of 1Mb or more:
        data   2.7Mb
        doc    3.5Mb
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘irlba’
      All declared Imports should be used.
    ```

*   checking for GNU extensions in Makefiles ... NOTE
    ```
    GNU make is a SystemRequirements.
    ```

# textreuse

Version: 0.1.4

## In both

*   checking Rd cross-references ... NOTE
    ```
    Package unavailable to check Rd xrefs: ‘tm’
    ```

# textTinyR

Version: 1.0.8

## In both

*   checking whether package ‘textTinyR’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/textTinyR/new/textTinyR.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘textTinyR’ ...
** package ‘textTinyR’ successfully unpacked and MD5 sums checked
configure: loading site script /usr/local/share/config.site
configure: creating cache NONE/var/config.cache
./configure: line 2004: NONE/var/config.cache: No such file or directory
checking for g++... g++
checking whether the C++ compiler works... yes
checking for C++ compiler default output file name... a.out
checking for suffix of executables...
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C++ compiler... yes
checking whether g++ accepts -g... yes
checking how to run the C++ preprocessor... g++ -E
checking for gcc... gcc
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking whether we are using the GNU C++ compiler... (cached) yes
checking whether g++ accepts -g... (cached) yes
checking whether clang++ supports C++11 features by default... no
checking whether clang++ supports C++11 features with -std=c++11... yes
checking for pkg-config... yes
checking for grep that handles long lines and -e... /usr/local/bin/ggrep
checking for egrep... /usr/local/bin/ggrep -E
checking for ANSI C header files... yes
checking for sys/types.h... yes
checking for sys/stat.h... yes
checking for stdlib.h... yes
checking for string.h... yes
checking for memory.h... yes
checking for strings.h... yes
checking for inttypes.h... yes
checking for stdint.h... yes
checking for unistd.h... yes
checking boost/locale.hpp usability... yes
checking boost/locale.hpp presence... yes
checking for boost/locale.hpp... yes
checking for main in -lboost_locale... no
configure: error: Unable to find the boost-locale. In DEBIAN/UBUNTU: sudo apt-get install libboost-all-dev; sudo apt-get install libboost-locale-dev, FEDORA : yum install boost-devel,
					OSX/brew : detailed installation instructions can be found in the README file
ERROR: configuration failed for package ‘textTinyR’
* removing ‘.../revdep/checks/textTinyR/new/textTinyR.Rcheck/textTinyR’

```
### CRAN

```
* installing *source* package ‘textTinyR’ ...
** package ‘textTinyR’ successfully unpacked and MD5 sums checked
configure: loading site script /usr/local/share/config.site
configure: creating cache NONE/var/config.cache
./configure: line 2004: NONE/var/config.cache: No such file or directory
checking for g++... g++
checking whether the C++ compiler works... yes
checking for C++ compiler default output file name... a.out
checking for suffix of executables...
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C++ compiler... yes
checking whether g++ accepts -g... yes
checking how to run the C++ preprocessor... g++ -E
checking for gcc... gcc
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking whether we are using the GNU C++ compiler... (cached) yes
checking whether g++ accepts -g... (cached) yes
checking whether clang++ supports C++11 features by default... no
checking whether clang++ supports C++11 features with -std=c++11... yes
checking for pkg-config... yes
checking for grep that handles long lines and -e... /usr/local/bin/ggrep
checking for egrep... /usr/local/bin/ggrep -E
checking for ANSI C header files... yes
checking for sys/types.h... yes
checking for sys/stat.h... yes
checking for stdlib.h... yes
checking for string.h... yes
checking for memory.h... yes
checking for strings.h... yes
checking for inttypes.h... yes
checking for stdint.h... yes
checking for unistd.h... yes
checking boost/locale.hpp usability... yes
checking boost/locale.hpp presence... yes
checking for boost/locale.hpp... yes
checking for main in -lboost_locale... no
configure: error: Unable to find the boost-locale. In DEBIAN/UBUNTU: sudo apt-get install libboost-all-dev; sudo apt-get install libboost-locale-dev, FEDORA : yum install boost-devel,
					OSX/brew : detailed installation instructions can be found in the README file
ERROR: configuration failed for package ‘textTinyR’
* removing ‘.../revdep/checks/textTinyR/old/textTinyR.Rcheck/textTinyR’

```
# themetagenomics

Version: 0.1.0

## In both

*   R CMD check timed out


# tidyr

Version: 0.7.2

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 23 marked UTF-8 strings
    ```

# toxboot

Version: 0.1.1

## In both

*   checking package dependencies ... NOTE
    ```
    Package suggested but not available for checking: ‘rmongodb’
    ```

# USAboundaries

Version: 0.3.0

## In both

*   checking package dependencies ... NOTE
    ```
    Package suggested but not available for checking: ‘USAboundariesData’
    ```

# utilsIPEA

Version: 0.0.4

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      4. Failure: nomes proprios sem espaços e com sobrenome (@test_extrai_nome_proprio.R#31)
      `nomes_proprios` not equal to `nomes_retorno`.
      Component "NomeProprio": 2 string mismatches
      Component "surname": 2 string mismatches


      testthat results ================================================================
      OK: 11 SKIPPED: 0 FAILED: 4
      1. Failure: nomes proprios (@test_extrai_nome_proprio.R#5)
      2. Failure: nomes proprios com sexo e sobrenome (@test_extrai_nome_proprio.R#14)
      3. Failure: nomes proprios sem sobrenome, sem sexo e sem stringdist (@test_extrai_nome_proprio.R#22)
      4. Failure: nomes proprios sem espaços e com sobrenome (@test_extrai_nome_proprio.R#31)

      Error: testthat unit tests failed
      Execution halted
    ```

# viridis

Version: 0.4.0

## In both

*   checking re-building of vignette outputs ... WARNING
    ```
    ...

    Attaching package: 'raster'

    The following object is masked from 'package:colorspace':

        RGB

    Loading required package: lattice
    Loading required package: latticeExtra
    Loading required package: RColorBrewer

    Attaching package: 'latticeExtra'

    The following object is masked from 'package:ggplot2':

        layer

    Quitting from lines 204-213 (intro-to-viridis.Rmd)
    Error: processing vignette 'intro-to-viridis.Rmd' failed with diagnostics:
    Cannot create RasterLayer object from this file; perhaps you need to install rgdal first
    Execution halted
    ```

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘stats’
      All declared Imports should be used.
    ```

# vqtl

Version: 1.2.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘iterators’ ‘knitr’ ‘testthat’
      All declared Imports should be used.
    ```

# widyr

Version: 0.1.0

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘methods’
      All declared Imports should be used.
    ```

# xml2

Version: 1.1.1

## In both

*   checking whether package ‘xml2’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘.../revdep/checks/xml2/new/xml2.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘xml2’ ...
** package ‘xml2’ successfully unpacked and MD5 sums checked
Found pkg-config cflags and libs!
Using PKG_CFLAGS=-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2
Using PKG_LIBS=-L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/lib -lxml2 -lz -lpthread -licucore -lm
** libs
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c RcppExports.cpp -o RcppExports.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c connection.cpp -o connection.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_doc.cpp -o xml2_doc.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_init.cpp -o xml2_init.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_namespace.cpp -o xml2_namespace.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_node.cpp -o xml2_node.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_output.cpp -o xml2_output.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_schema.cpp -o xml2_schema.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_url.cpp -o xml2_url.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_xpath.cpp -o xml2_xpath.o
clang++ -dynamiclib -Wl,-headerpad_max_install_names -undefined dynamic_lookup -single_module -multiply_defined suppress -L/Library/Frameworks/R.framework/Resources/lib -L/usr/local/lib -o xml2.so RcppExports.o connection.o xml2_doc.o xml2_init.o xml2_namespace.o xml2_node.o xml2_output.o xml2_schema.o xml2_url.o xml2_xpath.o -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/lib -lxml2 -lz -lpthread -licucore -lm -F/Library/Frameworks/R.framework/.. -framework R -Wl,-framework -Wl,CoreFoundation
ld: file not found: /usr/lib/system/libsystem_darwin.dylib for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [xml2.so] Error 1
ERROR: compilation failed for package ‘xml2’
* removing ‘.../revdep/checks/xml2/new/xml2.Rcheck/xml2’

```
### CRAN

```
* installing *source* package ‘xml2’ ...
** package ‘xml2’ successfully unpacked and MD5 sums checked
Found pkg-config cflags and libs!
Using PKG_CFLAGS=-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2
Using PKG_LIBS=-L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/lib -lxml2 -lz -lpthread -licucore -lm
** libs
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c RcppExports.cpp -o RcppExports.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c connection.cpp -o connection.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_doc.cpp -o xml2_doc.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_init.cpp -o xml2_init.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_namespace.cpp -o xml2_namespace.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_node.cpp -o xml2_node.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_output.cpp -o xml2_output.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_schema.cpp -o xml2_schema.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_url.cpp -o xml2_url.o
clang++  -I/Library/Frameworks/R.framework/Resources/include -DNDEBUG -I../inst/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/include/libxml2 -I".../revdep/library/xml2/Rcpp/include" -I".../revdep/library/xml2/BH/include" -I/usr/local/include   -fPIC  -Wall -g -O2  -c xml2_xpath.cpp -o xml2_xpath.o
clang++ -dynamiclib -Wl,-headerpad_max_install_names -undefined dynamic_lookup -single_module -multiply_defined suppress -L/Library/Frameworks/R.framework/Resources/lib -L/usr/local/lib -o xml2.so RcppExports.o connection.o xml2_doc.o xml2_init.o xml2_namespace.o xml2_node.o xml2_output.o xml2_schema.o xml2_url.o xml2_xpath.o -L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk/usr/lib -lxml2 -lz -lpthread -licucore -lm -F/Library/Frameworks/R.framework/.. -framework R -Wl,-framework -Wl,CoreFoundation
ld: file not found: /usr/lib/system/libsystem_darwin.dylib for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [xml2.so] Error 1
ERROR: compilation failed for package ‘xml2’
* removing ‘.../revdep/checks/xml2/old/xml2.Rcheck/xml2’

```
# zFactor

Version: 0.1.7

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespace in Imports field not imported from: ‘rootSolve’
      All declared Imports should be used.
    ```

