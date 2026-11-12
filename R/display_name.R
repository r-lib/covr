# The path of each trace of the coverage object `x`, relative to its root.
display_name <- function(x) {
  stopifnot(inherits(x, "coverage"))
  if (length(x) == 0) {
    return()
  }

  # Faster than getSrcFilename(), which matters for large coverage objects.
  filenames <- vcapply(x, function(x) {
    filename <- attr(x$srcref, "srcfile")$filename
    if (length(filename)) filename else ""
  })
  to_relative_path(filenames, attr(x, "root"))
}

# Removes the directory `base` and the separator after it from the start of
# each of the `path`s inside it. Other paths, such as those that only contain
# `base` or start with a sibling directory of the same prefix, and missing
# paths, are left as they are.
to_relative_path <- function(path, base) {
  if (is.null(base)) {
    return(path)
  }
  prefix <- paste0(sub("/+$", "", base), "/")
  inside <- startsWith(path, prefix) %in% TRUE
  path[inside] <- substring(path[inside], nchar(prefix) + 1)
  path
}

# Is each of the (normalized) `path`s one of the `roots`, or inside it? This
# compares whole path components, not the start of their names, so `/pkg2/a.R`
# isn't in `/pkg`. Missing paths give `NA`.
path_in_roots <- function(path, roots) {
  roots <- sub("/+$", "", normalize_path(roots))
  inside <- rep(FALSE, length(path))
  for (root in roots) {
    inside <- inside | path == root | startsWith(path, paste0(root, "/"))
  }
  inside
}

# Is each file C, C++, Fortran or Rust code, or a header?
is_native_file <- function(x) {
  is_compiled_file(x) | grepl("[.]rs$", x, ignore.case = TRUE)
}

# Keeps the coverage of files in the package. Native files in one of the
# `covr.gcov_additional_paths`, which gcov and llvm-cov are told to include,
# are kept as well.
filter_non_package_files <- function(x) {
  filenames <- vcapply(x, function(x) {
    get_source_filename(x$srcref, full.names = TRUE)
  })
  keep <- path_in_roots(filenames, attr(x, "package")$path)

  additional <- getOption("covr.gcov_additional_paths", NULL)
  if (length(additional)) {
    keep <- keep |
      (is_native_file(filenames) & path_in_roots(filenames, additional))
  }
  x[which(keep)]
}
