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

#' @export
print.coverage <- function(x, ...) {
  df <- as.data.frame(x)

  per_file_percents <-
    unlist(tapply(df$value, df$filename,
      FUN = function(x) sum(x > 0) / length(x),
      simplify = FALSE))

  overall_percentage <- sum(x > 0) / length(x)

  message(crayon::bold("Package Coverage: "), format_percentage(overall_percentage))

  if (any(per_file_percents < 1)) {
    by_coverage <- per_file_percents[order(per_file_percents)]

    for (i in which(by_coverage < 1)) {
      message(crayon::bold(paste0(names(by_coverage)[i], ": ")), format_percentage(by_coverage[i]))
    }
  }
}

format_percentage <- function(x) {
  color <- if (x >= .9) crayon::green
    else if (x >= .75) crayon::yellow
    else crayon::red

  color(sprintf("%02.2f%%", x * 100))
}
