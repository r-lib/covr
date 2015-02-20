#' Provide percent coverage of package
#'
#' @param coverage_result the coverage object returned from \code{\link{package_coverage}}
#' @param by_line whether to compute the percentage by covered lines or be covered expressions
#' @export
percent_coverage <- function(coverage_result, by_line = TRUE) {
  cov_df <- as.data.frame(coverage_result)
  if (by_line) {
    cov_df <- aggregate(value ~ filename + first_line,
      data = cov_df[c("filename", "first_line", "value")], FUN = sum)
  }

  sum(cov_df$value > 0) / nrow(cov_df)
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
  coverage_data <- as.data.frame(coverage_result)

  coverage_data[coverage_data$value == 0,
    c("filename", "first_line", "last_line", "first_column", "last_column", "value")]
}

#' @export
print.coverage <- function(x, by_line = TRUE, ...) {
  df <- as.data.frame(x)

  per_file_percents <- vapply(unique(df$filename),
    function(fn) {
      percent_coverage(df[df$filename == fn, ], by_line = by_line)
    },
    numeric(1)
  )

  overall_percentage <- percent_coverage(df, by_line = by_line)

  message(crayon::bold("Package Coverage: "),
    format_percentage(overall_percentage))

  by_coverage <- per_file_percents[order(per_file_percents,
      names(per_file_percents))]

  for (i in seq_along(by_coverage)) {
    message(crayon::bold(paste0(names(by_coverage)[i], ": ")),
      format_percentage(by_coverage[i]))
  }
}

format_percentage <- function(x) {
  color <- if (x >= .9) crayon::green
    else if (x >= .75) crayon::yellow
    else crayon::red

  color(sprintf("%02.2f%%", x * 100))
}
