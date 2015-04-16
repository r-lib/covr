#' @export
as.data.frame.coverage <- function(x, row.names = NULL, optional = FALSE, sort = TRUE, ...) {
  filenames <- vapply(x,
                      function(xx) attr(xx$srcref, "srcfile")$filename,
                      character(1), USE.NAMES = FALSE)

  vals <- t(vapply(x,
                   function(xx) c(xx$srcref, xx$value),
                   numeric(9), USE.NAMES = FALSE))

  colnames(vals) <- c("first_line", "first_byte", "last_line", "last_byte",
                      "first_column", "last_column", "first_parsed",
                      "last_parsed", "value")

  df <- data.frame(filename = filenames, vals, stringsAsFactors = FALSE)

  if (sort) {
    df <- df[order(df$filename, df$first_line, df$first_byte),]
  }

  rownames(df) <- NULL
  df
}
