#' Create an LCOV file
#'
#' Create an LCOV-compliant text report.
#' The format is documented at:
#' https://github.com/linux-test-project/lcov/
#'
#' @param cov the coverage object returned from [package_coverage()] or [file_coverage()]
#' @param filename the name of the LCOV file to write
#' @export
to_lcov <- function(cov, filename = "coverage.lcov") {
  df <- tally_coverage(cov, by = "line")

  # Open file for writing
  con <- withr::local_connection(file(filename, "w"))

  files <- unique(df$filename)

  for (f in files) {
    writeLines(paste0("SF:", f), con)

    file_data <- df[df$filename == f, ]

    # Sort by line number to be nice
    file_data <- file_data[order(file_data$line), ]

    writeLines(paste0("DA:", file_data$line, ",", file_data$value), con)

    writeLines("end_of_record", con)
  }

  invisible(df)
}
