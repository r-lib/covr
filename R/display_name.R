display_name <- function(x) {
  stopifnot(inherits(x, "coverage"))
  if (length(x) == 0) {
    return()
  }

  filenames <- vcapply(x, function(x) get_source_filename(x$srcref, full.names = TRUE))
  if (isTRUE(attr(x, "relative"))) {
    rex::re_substitutes(filenames, rex::rex(attr(x, "package")$path, "/"), "")
  } else {
    filenames
  }
}

filter_non_package_files <- function(x) {
  filenames <- vcapply(x, function(x) get_source_filename(x$srcref, full.names = TRUE))
  x[rex::re_matches(filenames, rex::rex(attr(x, "package")$path, "/"), "")]
}
