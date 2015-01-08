#' Provide percent coverage of package
#' 
#' @param coverage_results the coverage object returned from \code{\link{package_coverage}}
#' @export
percent_coverage <- function(coverage_results){
  coverage_data <- as.data.frame(coverage_results)
  n_lines <- nrow(coverage_data)
  n_not_zero <- sum(coverage_data$value != 0) # how many lines have a value that is not zero?
  
  perc_coverage <- n_not_zero / n_lines
  
  perc_coverage
}
