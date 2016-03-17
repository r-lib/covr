display_name <- function(x) {
  stopifnot(inherits(x, "coverage"))
  if (length(x) == 0) {
    return()
  }

  filenames <- vapply(x, function(x) getSrcFilename(x$srcref, full.names = TRUE), character(1))
  if (isTRUE(attr(x, "relative"))) {
    strip_path_before(filenames, attr(x, "package")$package)
  } else {
    filenames
  }
}

# assumes all vectors has the same prefix you want to remove.
strip_path_before <- function(x, before) {
  x <- normalize_path(x)
  d <- dirname(x[1])
  while(basename(d) != before && d != ".") {
    d <- dirname(d)
  }
  sub(paste0(d, "/"), "", x)
}
