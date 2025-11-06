#' Run covr on package and create report for GitLab
#'
#' Utilize internal GitLab static pages to publish package coverage.
#' Creates local covr report in a package subdirectory.
#' Uses the [pages](https://docs.gitlab.com/user/project/pages/)
#' GitLab job to publish the report.
#' @inheritParams codecov
#' @inheritParams report
#' @export
gitlab <- function(..., coverage = NULL, file = "public/coverage.html", quiet = TRUE) {
  if (is.null(coverage)) {
    coverage <- package_coverage(quiet = quiet, ...)
  }
  if (!quiet) {
    print(coverage)
  }

  out_file <- file.path(tempfile(), file)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  out_dir <- dirname(out_file)

  pkg_path <- attributes(coverage)$package$path

  report(coverage, file = out_file, browse = FALSE)

  file.copy(out_dir, pkg_path, recursive = TRUE)
}
