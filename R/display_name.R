display_name <- function(x) {
  stopifnot(inherits(x, "coverage"))
  if (length(x) == 0) {
    return()
  }

  filenames <- vapply(x, function(x) getSrcFilename(x$srcref, full.names = TRUE), character(1))
  if (isTRUE(attr(x, "relative"))) {
    rex::re_substitutes(filenames, rex::rex(attr(x, "package")$path, "/"), "")
  } else {
    filenames
  }
}

filter_non_package_files <- function(x) {
  filenames <- vapply(x, function(x) getSrcFilename(x$srcref, full.names = TRUE), character(1))
  x[rex::re_matches(filenames, rex::rex(attr(x, "package")$path, "/"), "")]
}
