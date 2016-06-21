## Resubmission

## Test environments
* OS X El Capitan, R 3.3.0
* ubuntu 12.04 (on travis-ci), R 3.2.5, 3.3.0, R-devel
* Windows Server 2012 R2 (x64), R 3.3.0
* win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs.

There were the following NOTEs:

  * checking dependencies in R code ... NOTE
  There are ::: calls to the package's namespace in its code. A package
    almost never needs to use ::: for its own objects:
      'count'

  The count function in question is what is used to instrument the test
  coverage in the external package.  This code is executed in the external
  package's namespace, so it needs to be a fully qualified call.  This count
  function is not exported because it never needs to be called by users.

  * Possibly mis-spelled words in DESCRIPTION:
  Codecov (6:51)
  Fortran (10:48)

  Both of these words are correctly spelled proper nouns.

  * URL: http://www.appveyor.com
  From: README.md
  Status: 403
  Message: Forbidden

  http://www.appveyor.com is a valid URL, however the IIS server it is running on
  does not seem to allow HEAD requests.  Running `curl -i http://www.appveyor.com`
  returns a valid response, however `-I` does not.

  * URL: https://coveralls.io/repos/new
  From: README.md
  Status: 403
  Message: Forbidden

  https://coveralls.io/repos/new is again a valid URL, however the user needs
  authentication in order to access it. It is the proper URL to direct users
  towards to enable their repository.

  * URL: https://drone.io
  From: README.md
  Status: 404
  Message: Not Found

  https://drone.io is again a valid URL however similar to the first error their
  backend server does not properly support HEAD requests.

## Reverse dependencies

Covr is a development tool only so its code is not actually run when building
any downstream dependencies. Nonetheless I have run R CMD check on the 47
downstream dependencies. There were no relevant Errors.

  Summary at: https://github.com/jimhester/covr/tree/master/revdep
