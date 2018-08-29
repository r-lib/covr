#' @title Run covr on package and create report for GitLab
#' @description
#'   Utilize internal GitLab static pages to publish package coverage.
#'   Creates local covr report in a package subdirectory.
#'   Use \code{pages} job documented in \url{https://docs.gitlab.com/ee/ci/yaml/README.html#pages}
#'   to publish the report.
#' @param ... arguments passed to [package_coverage()]
#' @param coverage an existing coverage object to submit, if `NULL`,
#'   [package_coverage()] will be called with the arguments from `...`
#' @param pubdir the subdirectory of the report to publish
#' @param file the filename of the html file
#' @param quiet if `FALSE`, print the coverage before submission.
#' @export
gitlab = function(..., coverage = NULL, pubdir = "public", file = "coverage.html", quiet = TRUE) {
  if (is.null(coverage)) {
    coverage = package_coverage(quiet = quiet, ...)
  }
  if (!quiet) {
    print(coverage)
  }
  
  tmpdir = tempdir()
  if (!dir.exists(file.path(tmpdir, pubdir)))
    dir.create(file.path(tmpdir, pubdir))
  tmpdir = report(coverage, file = file.path(tmpdir, pubdir, file), browse = FALSE)
  file.copy(dirname(tmpdir), attributes(coverage)$package$path, recursive = TRUE)
  cat(sprintf("Code coverage: %2.2f %%\n", covr::percent_coverage(coverage)))
}
