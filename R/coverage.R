#' Coverage objects
#'
#' [package_coverage()], [file_coverage()], [code_coverage()],
#' [function_coverage()] and [environment_coverage()] return a `coverage`
#' object, which records how many times each part of the code was executed.
#'
#' @section Working with coverage objects:
#' Rather than using the list directly, you will usually want to:
#'
#' * Get a data frame with one row for each expression with [as.data.frame()]
#'   ([as.data.frame.coverage()]), or one row for each line or function with
#'   [tally_coverage()].
#' * Get the overall percentage with [percent_coverage()], or the percentage
#'   for each file with [coverage_to_list()].
#' * Find the lines or functions which were never run with [zero_coverage()],
#'   list them as ranges with `print(x, missing = TRUE)`, or show their source
#'   with [annotate_coverage()].
#' * Get the execution counts as a named numeric vector with [value()].
#' * Browse the coverage with [report()] or [file_report()].
#'
#' @section Structure:
#' A `coverage` object is a named list with one element for each traced
#' expression of R code and each line of compiled code. Each element is a list
#' with:
#'
#' * `value`: the number of times the expression or line was executed.
#' * `srcref`: a [srcref][base::srcref] with its location. Its `srcfile`
#'   attribute holds the name and lines of the source file.
#' * `functions`: the name of the function containing it, or `NA` for compiled
#'   code.
#' * `tests`: only present with `options(covr.record_tests = TRUE)`, see
#'   [covr.record_tests].
#'
#' The names of the elements are the base name of the file followed by the
#' eight numbers of the srcref, separated by `:`. For example
#' `foo.R:10:3:12:4:3:4:10:12` is an expression from line 10 column 3 to line
#' 12 column 4 of `foo.R` (see [as.data.frame.coverage()] for the meaning of
#' each number). The `srcfile` of the `srcref`, or the `filename` column of
#' [as.data.frame()], gives the path of the file.
#'
#' Coverage objects from [package_coverage()] also have the attributes
#' `package` (information about the package, such as its `package` name and
#' `path`), `root` (the directory file names are relative to, or `NULL`) and,
#' if `clean = FALSE`, `library` (the `install_path`).
#'
#' With `options(covr.record_tests = TRUE)`, coverage objects also have a
#' `tests` attribute with the test calls, see [covr.record_tests].
#'
#' With `options(covr.branch_coverage = TRUE)`, coverage objects also have a
#' `branches` attribute with the branches of each `if` and `switch()`, see
#' [covr.branch_coverage].
#'
#' @examples
#' cov <- code_coverage("add <- function(x, y) { x + y }", "add(1, 2)")
#' cov
#' as.data.frame(cov)
#' names(cov)
#' cov[[1]]$value
#' @name coverage
NULL
