This release changes the package license from MIT to GPL-3. I obtained approval
from all contributors <https://github.com/jimhester/covr/issues/256> for the license change.

## Test environments
* OS X El Capitan, R 3.3.0
* ubuntu 12.04 (on travis-ci), R 3.2.5, 3.3.0, R-devel
* Windows Server 2012 R2 (x64), R 3.3.0
* r-hub
 - Windows Server 2008 R2 SP1, R-devel, 32/64 bit
 - Debian Linux, R-devel, GCC ASAN/UBSAN
 - Fedora Linux, R-devel, clang, gfortran
 - Ubuntu Linux 16.04 LTS, R-release, GCC

## R CMD check results
There were no NOTEs, ERRORs or WARNINGs.

## Reverse dependencies

Covr is a development tool only so its code is not actually run when building
any downstream dependencies. Nonetheless I have run R CMD check on the 262
downstream dependencies.

The errors in biolink, geofacet, Wmisc are due to `lintr::expect_lint_free()`
not working properly when it is used while running `devtools::revdep_check()`.
I opened issue [#251](https://github.com/jimhester/lintr/issues/251) to track
this bug in lintr.

I did not see any other errors that were relevant to the covr changes.

  Summary at: https://github.com/jimhester/covr/tree/master/revdep
