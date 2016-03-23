## 2.0.0 ##
* Rewrote loading and saving to support parallel code and tests including
  `quit()` calls.
* Made passing code to function_coverage() and package_coverage() _not_ use
  non-standard evaluation.
* `NULL` statements are analyzed for coverage (#156, @krlmlr).
* Finer coverage analysis for braceless `if`, `while` and `for` statements (#154, @krlmlr).

## 1.3.0 ##
* Set `.libPaths()` in subprocess to match those in calling process (#140, #147).
* Move devtools dependency to suggests, only needed on windows
* move htmltools to suggests

## Initial Release ##
