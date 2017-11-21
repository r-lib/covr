## Test environments
* OS X El Capitan, R 3.4.2
* ubuntu 14.04 (on travis-ci), R 3.3.5, 3.4.2, R-devel
* Windows Server 2012 R2 (x64), R 3.4.2
* r-hub
 - Windows Server 2008 R2 SP1, R-devel, 32/64 bit
 - Debian Linux, R-devel, GCC ASAN/UBSAN
 - Fedora Linux, R-devel, clang, gfortran
 - Ubuntu Linux 16.04 LTS, R-release, GCC

## R CMD check results
There were no NOTEs, ERRORs or WARNINGs.

## Reverse dependencies

covr is tool used only in package development. It is not actually run in any
downstream dependencies. Nonetheless I have run R CMD check on the 337
downstream dependencies.

I did not see any errors that were relevant to covr changes.

  Summary at: https://github.com/r-lib/covr/tree/master/revdep#readme
