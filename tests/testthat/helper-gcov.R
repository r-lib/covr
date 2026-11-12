# A package with a source file and the notes file of its object, as left by
# compiling it with coverage.
local_gcov_package <- function(env = parent.frame()) {
  pkg <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(pkg, "src"))
  writeLines("int f() { return 1; }", file.path(pkg, "src", "f.c"))
  file.create(file.path(pkg, "src", "f.gcno"))
  normalize_path(pkg)
}

# Writes the text report of `source` into the current directory, as gcov does
write_gcov_report <- function(file = "f.c.gcov", source = "f.c") {
  writeLines(
    c(
      paste0("        -:    0:Source:", source),
      "        1:    1:int f() { return 1; }"
    ),
    file
  )
}

# A gcov that writes the report of `f.c`
fake_gcov_run <- function(...) {
  write_gcov_report()
  invisible()
}

# A coverage object with a line of each of `files`, which needn't exist
coverage_of_files <- function(files, root = NULL, package_path = NULL) {
  traces <- lapply(files, function(file) {
    srcfile <- srcfilecopy(file, "x")
    structure(
      list(srcref = srcref(srcfile, c(1, 1, 1, 1)), value = 1, functions = NA),
      class = "line_coverage"
    )
  })
  names(traces) <- paste0("trace", seq_along(files))
  structure(
    traces,
    class = "coverage",
    root = root,
    package = list(path = package_path)
  )
}
