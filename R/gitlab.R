#' Run covr on package and create report for GitLab
#'
#' Utilize internal GitLab static pages to publish package coverage.
#' Creates local covr report in a package subdirectory.
#' Uses the [pages](https://docs.gitlab.com/user/project/pages/)
#' GitLab job to publish the report.
#' @inheritParams codecov
#' @param file The path of the HTML report, relative to the root directory of
#'   the package (not the working directory). Directories that don't exist are
#'   created.
#' @returns The path of the report, invisibly.
#' @export
gitlab <- function(
  ...,
  coverage = NULL,
  file = "public/coverage.html",
  quiet = TRUE
) {
  if (is.null(coverage)) {
    coverage <- package_coverage(quiet = quiet, ...)
  }
  if (!quiet) {
    print(coverage)
  }

  pkg_path <- attributes(coverage)$package$path

  invisible(report(coverage, file = file.path(pkg_path, file), browse = FALSE))
}
