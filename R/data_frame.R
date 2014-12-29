#' @export
as.data.frame.coverage <- function(x, ...) {
  re <-
    rex::rex(
      capture(name = "filename", something), ":",
      capture(name = "first_line", something), ":",
      capture(name = "first_byte", something), ":",
      capture(name = "last_line", something), ":",
      capture(name = "last_byte", something), ":",
      capture(name = "first_column", something), ":",
      capture(name = "last_column", something), ":",
      capture(name = "first_parsed", something), ":",
      capture(name = "last_parsed", something))

  df <- rex::re_matches(names(x), re)

  df[] <- lapply(df, type.convert, as.is = TRUE)
  df$value <- unlist(x)
  df
}
