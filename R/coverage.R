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

#' Combine coverage objects
#'
#' Combine the coverage of several runs, e.g. of tests in different
#' directories, into a single coverage object. The counts of traces present in
#' more than one object are added, and traces only in some of the objects are
#' appended. Tests recorded with `options(covr.record_tests = TRUE)` are
#' combined as well.
#'
#' The result keeps the attributes of the first object, such as the package
#' and root used for relative paths, except that the lines excluded from line
#' coverage are the union of the excluded lines of all objects. As with
#' `package_coverage(type = c("tests", "examples"))`, the result only has a
#' `type` if all objects have the same `type`.
#'
#' As with any S3 method for [c()], this method is only used when the first
#' argument is a coverage object.
#'
#' @param ... Coverage objects, e.g. from [package_coverage()] or
#'   [file_coverage()]. They must all be for the same package, or all have no
#'   package, like the results of [file_coverage()] and [code_coverage()].
#'   `NULL` arguments are dropped.
#' @return A coverage object.
#' @export
#' @examples
#' source_file <- tempfile(fileext = ".R")
#' writeLines(
#'   c(
#'     "add <- function(x, y) {",
#'     "  x + y",
#'     "}",
#'     "subtract <- function(x, y) {",
#'     "  x - y",
#'     "}"
#'   ),
#'   source_file
#' )
#' add_test <- tempfile(fileext = ".R")
#' writeLines("add(1, 2)", add_test)
#' subtract_test <- tempfile(fileext = ".R")
#' writeLines("subtract(2, 1)", subtract_test)
#'
#' add_cov <- file_coverage(source_file, add_test)
#' subtract_cov <- file_coverage(source_file, subtract_test)
#' percent_coverage(add_cov)
#' percent_coverage(c(add_cov, subtract_cov))
c.coverage <- function(...) {
  covs <- Filter(Negate(is.null), list(...))
  if (!all(vlapply(covs, inherits, "coverage"))) {
    covr_abort(
      "All arguments to {.fn c} must be coverage objects.",
      class = "covr_combine_error"
    )
  }
  packages <- unique(vcapply(covs, function(x) {
    attr(x, "package")$package %||% NA_character_
  }))
  if (length(packages) > 1L) {
    covr_abort(
      c(
        "Can't combine coverage of different packages.",
        x = "Packages: {.pkg {packages}}."
      ),
      class = "covr_combine_error"
    )
  }

  merged <- merge_coverage(lapply(covs, coverage_to_counters))

  tests <- merged[["tests"]]
  merged[["tests"]] <- NULL
  branches <- as_branch_list(merged[["branches"]])
  merged[["branches"]] <- NULL
  merged <- lapply(merged, function(trace) {
    if (!is.null(trace$tests)) {
      trace$tests <- trace$tests$tally
    }
    trace
  })

  attrs <- attributes(covs[[1L]])
  attrs$names <- names(merged)
  attrs$tests <- tests
  attrs$branches <- branches
  attrs$excluded_lines <- union_excluded_lines(
    lapply(covs, attr, "excluded_lines")
  )
  types <- unique(lapply(covs, attr, "type"))
  if (length(types) > 1L) {
    attrs$type <- NULL
  }
  attributes(merged) <- attrs
  merged
}

# Convert a coverage object back to the list of traces used by
# `merge_coverage()`, with the recorded tests in a `tests` element.
coverage_to_counters <- function(x) {
  counters <- lapply(unclass(x), function(trace) {
    if (!is.null(trace$tests)) {
      trace$tests <- list(tally = trace$tests)
    }
    trace
  })
  counters[["tests"]] <- attr(x, "tests")
  counters[["branches"]] <- attr(x, "branches")
  counters
}

union_excluded_lines <- function(excluded) {
  excluded <- unlist(excluded, recursive = FALSE)
  if (length(excluded) == 0L) {
    return(NULL)
  }
  lapply(split(excluded, names(excluded)), function(lines) {
    sort(unique(unlist(lines)))
  })
}
