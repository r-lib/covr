# A copy of a compiled fixture package loaded with pkgload::load_all(), so the
# instrumented build doesn't write to the fixture.
local_compiled_package <- function(
  pkg = "TestCompiled",
  frame = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = frame)
  file.copy(test_path(pkg), dir, recursive = TRUE)
  path <- normalize_path(file.path(dir, pkg))
  # Other tests build the fixture in place, possibly at the same time
  clean_objects(path)
  clean_gcov(path)
  pkgload::load_all(path, quiet = TRUE)
  withr::defer(pkgload::unload(pkg), envir = frame)
  path
}

# Makes the same calls as TestCompiled's tests, without nesting test_that()
local_compiled_test_script <- function(frame = parent.frame()) {
  file <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(
    c(
      "simple(1); simple(2); simple(3); simple(-1)",
      "simple3(1); simple3(2)",
      "simple4(3L); simple4(-1L)"
    ),
    file
  )
  file
}

compiled_counts <- function(coverage, file) {
  tally <- tally_coverage(coverage)
  tally <- tally[basename(tally$filename) == file, ]
  stats::setNames(tally$value, tally$line)
}
