#' Provide percent coverage of package
#'
#' @param coverage_result the coverage object returned from \code{\link{package_coverage}}
#' @export
percent_coverage <- function(coverage_result){
  coverage_data <- as.data.frame(coverage_result)
  num_lines <- length(unique(coverage_data$first_line))
  not_zero <- coverage_data$value != 0
  num_not_zero <- length(unique(coverage_data[not_zero, 'first_line']))

  perc_coverage <- num_not_zero / num_lines

  perc_coverage
}

#' Provide locations of zero coverage
#'
#' When examining the test coverage of a package, it is useful to know if there are
#' any locations where there is \bold{0} test coverage.
#'
#' @param coverage_result a coverage object returned from
#' 	\code{\link{package_coverage}}, or its data frame conversion
#' @export
zero_coverage <- function(coverage_result) {
  coverage_data <- if (is.data.frame(coverage_result)) {
    coverage_result
  } else {
    as.data.frame(coverage_result)
  }

  zero_locs <- coverage_data$value == 0

  coverage_zero <- coverage_data[zero_locs, c("filename", "first_line", "last_line", "value")]
  rownames(coverage_zero) <- NULL

  coverage_zero
}

#' @export
print.coverage <- function(x, ...) {
  df <- as.data.frame(x)

  per_file_percents <- vapply(unique(df$filename), function(fn) {
    percent_coverage(df[df$filename == fn, ])
      }, 0)

  overall_percentage <- percent_coverage(x)

  message(crayon::bold("Package Coverage: "), format_percentage(overall_percentage))

  by_coverage <- per_file_percents[order(per_file_percents)]

  for (i in seq_along(by_coverage)) {
    message(crayon::bold(paste0(names(by_coverage)[i], ": ")), format_percentage(by_coverage[i]))
  }
}

format_percentage <- function(x) {
  color <- if (x >= .9) crayon::green
    else if (x >= .75) crayon::yellow
    else crayon::red

  color(sprintf("%02.2f%%", x * 100))
}
