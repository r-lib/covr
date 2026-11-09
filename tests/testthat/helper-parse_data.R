local_keep_parse_data_package <- function(frame = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = frame)
  pkg <- file.path(dir, "parsePkg")
  dir.create(file.path(pkg, "R"), recursive = TRUE)
  writeLines(
    c(
      "Package: parsePkg",
      "Title: Test",
      "Version: 0.0.1",
      "Description: Test.",
      "License: GPL-3"
    ),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("export(f, h)", file.path(pkg, "NAMESPACE"))
  # the first file shifts the lines of the second in the collated source
  writeLines(
    c("g <- function() {", "  1", "}", "f <- function(x) x"),
    file.path(pkg, "R", "a.R")
  )
  writeLines(
    c("h <- function(x) {", "  if (x)", "    1", "}"),
    file.path(pkg, "R", "b.R")
  )
  pkg
}

parse_srcrefs <- function(text) {
  exprs <- parse(text = text, keep.source = TRUE)
  list(exprs = exprs, refs = getSrcref(exprs))
}
