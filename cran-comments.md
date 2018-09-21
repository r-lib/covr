## Test environments
* OS X El Capitan, R 3.5.1
* ubuntu 14.04 (on travis-ci), R 3.5.1, 3.4.5, R-devel
* Windows Server 2012 R2 (x64), R 3.5.1
* r-hub
 - Windows Server 2008 R2 SP1, R-devel, 32/64 bit
 - Debian Linux, R-devel, GCC ASAN/UBSAN
 - Fedora Linux, R-devel, clang, gfortran
 - Ubuntu Linux 16.04 LTS, R-release, GCC

## R CMD check results
There were no NOTEs, ERRORs or WARNINGs.

## Reverse dependencies

covr is tool used only in package development. It is generally not actually run
by any downstream dependencies. Nonetheless I have run R CMD check on the 3
hard downstream dependencies.

I did not see any errors that were relevant to covr changes.

  Summary at: https://github.com/r-lib/covr/tree/master/revdep#readme
