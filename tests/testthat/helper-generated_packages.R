# Write the source of the package `name` in the directory `dir`, with the
# `files` of R code (a list of lines named by file), and returns its path.
write_test_package <- function(
  dir,
  name,
  files,
  imports = NULL,
  namespace = character()
) {
  path <- file.path(dir, name)
  dir.create(file.path(path, "R"), recursive = TRUE)
  writeLines(
    c(
      paste("Package:", name),
      "Version: 0.1.0",
      "Title: T",
      "Description: T.",
      if (!is.null(imports)) paste("Imports:", imports)
    ),
    file.path(path, "DESCRIPTION")
  )
  writeLines(namespace, file.path(path, "NAMESPACE"))
  for (file in names(files)) {
    writeLines(files[[file]], file.path(path, "R", file))
  }
  path
}

# Install the packages in the directories `paths`, in this order, with their
# source references into the library `lib`.
install_test_packages <- function(paths, lib) {
  withr::local_envvar(
    R_ENVIRON = NA,
    R_PROFILE = NA,
    R_LIBS = paste(c(lib, .libPaths()), collapse = .Platform$path.sep)
  )
  for (path in paths) {
    status <- system2(
      file.path(R.home("bin"), "R"),
      c(
        "CMD",
        "INSTALL",
        "--with-keep.source",
        "-l",
        shQuote(lib),
        shQuote(path)
      ),
      stdout = FALSE,
      stderr = FALSE
    )
    stopifnot(status == 0)
  }
}
