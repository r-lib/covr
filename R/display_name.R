#' Retrieve the path name (filenaem) for each coverage object
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
  if (isTRUE(attr(x, "relative"))) {
    to_relative_path(filenames, attr(x, "package")$path)
  } else {
    filenames
  }
}

to_relative_path <- function(path, base) {
  rex::re_substitutes(path, rex::rex(base, "/"), "")
}

filter_non_package_files <- function(x) {
  filenames <- vcapply(x, function(x) get_source_filename(x$srcref, full.names = TRUE))
  x[rex::re_matches(filenames, rex::rex(attr(x, "package")$path, "/"), "")]
}
