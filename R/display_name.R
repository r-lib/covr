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
