## Resubmission

This is a resubmission. In this version I have:

* Excluded the `revdep/` directory from the package, which was included by
  mistake.
* Kept exporting `display_name()`, which devtools uses, so devtools' tests
  pass again.

## Major release

This is a major release. It removes a few rarely used functions and arguments
(`azure()`, and the `pre_clean` and `exclusions` arguments of
`package_coverage()`). It now requires R >= 4.1.0.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

We checked the 12 packages that depend on, import or link to covr (11 on CRAN
and 1 on Bioconductor), comparing R CMD check results with the CRAN and the
development version of covr.

* We saw 1 new problem, in mutator. It reads covr's internal counters
  directly, which this release no longer updates while code runs. covr now
  exports `current_coverage()` for this
  (https://github.com/r-lib/covr/pull/759), and we have sent the maintainer a
  pull request that uses it and still works with the CRAN version of covr
  (https://github.com/PRL-PRG/mutator/pull/16).
* We failed to check 0 packages.

The CRAN incoming checks also showed a new NOTE for lwgeom, from a "PROJ
versions differ" warning between its system libraries and sf's, which is
unrelated to covr.
