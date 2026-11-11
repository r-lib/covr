#' Deprecated functions
#'
#' @description
#' These functions are deprecated and warn once per session. They take the
#' same arguments and return the same value as the functions that replace
#' them:
#'
#' * `to_cobertura()` is now [cobertura()].
#' * `to_sonarqube()` is now [sonarqube()].
#'
#' @inheritParams cobertura
#' @inheritParams sonarqube
#' @param filename the name of the output file
#' @name covr-deprecated
#' @keywords internal
NULL

#' @rdname covr-deprecated
#' @export
to_cobertura <- function(cov, filename = "cobertura.xml") {
  warn_deprecated("to_cobertura", "cobertura")
  cobertura(cov, filename = filename)
}

#' @rdname covr-deprecated
#' @export
to_sonarqube <- function(cov, filename = "sonarqube.xml", path_prefix = NULL) {
  warn_deprecated("to_sonarqube", "sonarqube")
  sonarqube(cov, filename = filename, path_prefix = path_prefix)
}
