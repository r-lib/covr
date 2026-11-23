# Installs copies of TestNestedOuter and TestNestedInner, which imports it,
# with their source references into a temporary library. Returns the library
# and the directory of the copies of their source.
local_nested_library <- function(frame = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = frame)
  src <- file.path(dir, "src")
  lib <- file.path(dir, "lib")
  dir.create(src)
  dir.create(lib)
  file.copy(
    test_path(c("TestNestedOuter", "TestNestedInner")),
    src,
    recursive = TRUE
  )
  # Under rcmdcheck, R_PROFILE is callr's site profile, which sets
  # `.libPaths()` to the libraries of the check.
  withr::local_envvar(R_ENVIRON = NA, R_PROFILE = NA)
  status <- system2(
    file.path(R.home("bin"), "R"),
    c(
      "CMD",
      "INSTALL",
      "--with-keep.source",
      "-l",
      shQuote(lib),
      shQuote(file.path(src, c("TestNestedOuter", "TestNestedInner")))
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  stopifnot(status == 0)
  list(lib = normalizePath(lib), src = normalizePath(src))
}

# Run `code` in a new R process that uses the library `lib` first.
run_with_library <- function(lib, code, env = character()) {
  withr::local_envvar(
    R_LIBS = paste(c(lib, .libPaths()), collapse = .Platform$path.sep),
    R_ENVIRON = NA,
    R_PROFILE = NA,
    env
  )
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "-e", shQuote(code)),
    stdout = FALSE,
    stderr = FALSE
  )
  stopifnot(status == 0)
}
