#' Retrieve the path name (filename) for each coverage object
#'
#' @param x A coverage object
#' @keywords internal
#' @export
display_name <- function(x) {
  stopifnot(inherits(x, "coverage"))
  if (length(x) == 0) {
    return()
  }

  filenames <- vcapply(x, function(x) get_source_filename(x$srcref, full.names = TRUE))
  to_relative_path(filenames, attr(x, "root"))
}

to_relative_path <- function(path, base) {
  if (is.null(base)) {
    return(path)
  }
  rex::re_substitutes(path, rex::rex(base, "/"), "")
}

filter_non_package_files <- function(x) {
  filenames <- vcapply(x, function(x) get_source_filename(x$srcref, full.names = TRUE))
  x[rex::re_matches(filenames, rex::rex(attr(x, "package")$path, "/"), "")]
}
