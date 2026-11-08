#' Run covr on a package and output the result so it is available on Azure Pipelines
#'
#' Deprecated. Use [to_cobertura()], which this function calls, instead.
#' @inheritParams codecov
#' @inheritParams to_cobertura
#' @export
azure <- function(
  ...,
  coverage = package_coverage(..., quiet = quiet),
  filename = "coverage.xml",
  quiet = TRUE
) {
  covr_warn(c(
    "{.fn azure} is deprecated.",
    i = "Use {.fn to_cobertura} instead."
  ))
  to_cobertura(coverage, filename = filename)
}
