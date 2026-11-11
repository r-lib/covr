#' Run covr on a package and output the result so it is available on Azure Pipelines
#'
#' Deprecated. Use [cobertura()], which this function calls, instead.
#' @inheritParams codecov
#' @inheritParams cobertura
#' @export
azure <- function(
  ...,
  coverage = package_coverage(..., quiet = quiet),
  filename = "coverage.xml",
  quiet = TRUE
) {
  covr_warn(c(
    "{.fn azure} is deprecated.",
    i = "Use {.fn cobertura} instead."
  ))
  cobertura(coverage, filename = filename)
}
