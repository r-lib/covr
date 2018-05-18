## 3.1.0 ##

## Breaking changes

* `shine()` has been deprecated in favor of `report()`.

## New Features

* Add support for `.covrignore` files (#238), to exclude files from the coverage.

* Support future versions of R which do not use parse data by default (#309).

* Allow using `trace_calls()` for manually adding functions to package trace
  that are not found automatically (#295, @mb706).

## Bugfixes

* Fix errors when R is not in the `PATH` (#291)

* Fix line computations when relative paths are being used (#242).

* Fix for Coveralls `Build processing error.` (#285) on pro accounts from
  Travis CI (#306, @kiwiroy).

* Keep attributes of function bodies (#311, @gaborcsardi)

## 3.0.1 ##
* Add an RStudio Addin for running a coverage report.

* Never use mcexit fix on windows (#223).

* Fix for a performance regression in parsing and reading parse data (#274).

* Fix `switch` support for packages, which was broken due to a bug in
  how parse data is stored in packages.

* Improve behavior of `switch` coverage, it now supports default values and
  fall through properly.

* Add `-p` flag to gcov command to preserve file paths. Fixes a bug where
  gcov output didn't get reported when multiple compiled source files had
  the same name (#271, @patperry)

## 3.0.0 ##
* The covr license has been changed to GPL-3.
* Set environment variable `R_COVR=true` when covr is running (#236, #268).
* Made the gather-and-merge-results step at the end of package_coverage() more memory efficient (#226, @HenrikBengtsson).
* Support code coverage with icc (#247, @QinWang).

## 2.2.2 ##
* `filter_not_package_files()` now works if a source reference does not have a filename (#254, @hughjonesd).
* Fix test broken with xml2 v1.1.0
* Filter out non-local filenames from results (#237).
* Vignette rewrite / improvements (#229, @CSJCampbell).
* Fix code that returns `structure(NULL, *)` which is deprecated in R 3.4.0 (#260, #261, @renkun-ken).

## 2.2.1 ##
* Fix test broken with DT 0.2

## 2.2.0 ##
* Fix tests broken with updated htmlwidgets
* Change report tab title based on filename (Chen Liang).
* Add support for cobertura XML output (@wligtenberg).
* Add mcparallel support by patching `mcparallel:::mcexit()`
  automatically for packages using parallel (#195, @kforner).

## 2.1.0 ##
* Add support for GitLab CI (#190, @enbrown).
* Update exclusion documentation to include line_exclusions and function
  exclusions (#191).
* Support coverage of R6 methods (#174).
* Explicitly set default packages (including methods) (#183, #180)
* Set R_LIBS and R_LIBS_SITE as well as R_LIBS_USER (#188).
* Automatically exclude RcppExport files (#170).
* Memoised and Vectorized functions now able to be tracked.

## 2.0.1 ##
* Support for filtering by function as well as line.
* Now tracks coverage for RC methods
* Rewrote loading and saving to support parallel code and tests including
  `quit()` calls.
* Made passing code to `function_coverage()` and `package_coverage()` _not_ use
  non-standard evaluation.
* `NULL` statements are analyzed for coverage (#156, @krlmlr).
* Finer coverage analysis for brace-less `if`, `while` and `for` statements (#154, @krlmlr).
* Run any combination of coverage types (#104, #133)
* Remove inconsistencies in line counts between shiny app and services (#129)
* Include header files in gcov output (#112)
* Add support for C++11 (#131)
* Always clean gcov files even on failure (#108)
* zero_coverage works with RStudio markers (#119)
* Remove the devtools dependency

## 1.3.0 ##
* Set `.libPaths()` in subprocess to match those in calling process (#140, #147).
* Move devtools dependency to suggests, only needed on windows
* move htmltools to suggests

## Initial Release ##
