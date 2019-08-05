#' Run covr on a package and output the result so it is available on Azure Pipelines
#' @inheritParams codecov
#' @inheritParams to_cobertura
#' @export
azure <- function(
  ...,
  coverage = package_coverage(..., quiet = quiet), filename = "coverage.xml", quiet = TRUE) {

  to_cobertura(coverage, filename = filename)
}
