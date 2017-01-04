This release fixes a test error when run with the soon to be submitted xml2
1.1.0 release.

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
any downstream dependencies. Nonetheless I have run R CMD check on the 151
downstream dependencies. There were no relevant Errors.

  Summary at: https://github.com/jimhester/covr/tree/master/revdep
