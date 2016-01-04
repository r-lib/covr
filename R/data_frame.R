#' @export
as.data.frame.coverage <- function(x, row.names = NULL, optional = FALSE, sort = TRUE, ...) {
  column_names <- c("filename", "functions", "first_line", "first_byte", "last_line", "last_byte",
               "first_column", "last_column", "first_parsed",
               "last_parsed", "value")

  res <- setNames(c(list(character(0)), rep(list(numeric(0)), times = length(column_names) - 1)),
                  column_names)
  if (length(x)) {
    res$filename <- display_name(x)
    res$functions <- vapply(x, function(xx) xx$functions[1], character(1))

    vals <- t(vapply(x,
                     function(xx) c(xx$srcref, xx$value),
                     numeric(9), USE.NAMES = FALSE))
    for (i in seq_len(NCOL(vals))) {
      res[[i + 2]] <- vals[, i]
    }
  }

  df <- data.frame(res, stringsAsFactors = FALSE, check.names = FALSE)

  if (sort) {
    df <- df[order(df$filename, df$first_line, df$first_byte), ]
  }

  rownames(df) <- NULL
  df
}
