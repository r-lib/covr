#' Provide percent coverage of package
#'
#' @param coverage_result the coverage object returned from \code{\link{package_coverage}}
#' @export
percent_coverage <- function(coverage_result){
  coverage_data <- as.data.frame(coverage_result)
  num_lines <- nrow(coverage_data)
  num_not_zero <- sum(coverage_data$value != 0) # how many lines have a value that is not zero?

  perc_coverage <- num_not_zero / num_lines

  perc_coverage
}

#' Provide locations of zero coverage
#'
#' When examining the test coverage of a package, it is useful to know if there are 
#' any locations where there is \bold{0} test coverage.
#'
#' @param coverage_result a coverage object returned from \code{\link{package_coverage}}
#' @export
zero_coverage <- function(coverage_result){
  coverage_data <- as.data.frame(coverage_result)

  zero_locs <- coverage_data$value == 0

  coverage_zero <- coverage_data[zero_locs, c("filename", "first_line", "last_line", "value")]
  rownames(coverage_zero) <- NULL

  coverage_zero
}
