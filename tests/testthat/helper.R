is_r_devel <- function() {
  startsWith(R.version$status, "Under development")
}

is_win_r41 <- function() {
  x <- getRversion()
  is_windows() && x$major == 4 && x$minor == 1
}

# The tests with the TestRust package need rustc and the tools to measure the
# coverage of Rust code (`rustup component add llvm-tools`), which isn't
# supported on Windows.
skip_if_no_rust_coverage <- function() {
  skip_on_os("windows")
  toolchain <- rust_toolchain(".")
  skip_if(
    is.null(toolchain$profiler_runtime) ||
      is.null(toolchain$llvm_cov) ||
      is.null(toolchain$llvm_profdata),
    "The Rust toolchain or its llvm-tools aren't installed"
  )
}

# Line 3 has three expressions on it, inside the multi-line `lapply()` call,
# and the middle one, `any(x)`, never runs; line 6 has two functions, and only
# `g()` runs (#620).
shared_line_coverage <- function() {
  code_coverage(
    paste(
      "f <- function(x) {",
      "  lapply(x, function(x) {",
      "    if (is.logical(x)) any(x) else sum(x)",
      "  })",
      "}",
      "g <- function() 1; h <- function() 2",
      sep = "\n"
    ),
    "f(1:2); g()"
  )
}

local_r_file <- function(lines, frame = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(lines, path)
  path
}

# Capture what `code` prints to stdout and stderr, as lines without the `\r`
# of the Windows line endings in the output of child processes.
capture_streams <- function(code) {
  stderr <- utils::capture.output(
    stdout <- utils::capture.output(code),
    type = "message"
  )
  list(stdout = sub("\r$", "", stdout), stderr = sub("\r$", "", stderr))
}

# Installs a copy of a test package with `R CMD INSTALL` options `args` and
# removes the copy, like `remotes::install_github()` removes the source it
# installs from. Returns the installed package directory.
local_installed_package <- function(name, args, frame = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = frame)
  file.copy(test_path(name), dir, recursive = TRUE)
  src <- file.path(dir, name)
  lib <- file.path(dir, "lib")
  dir.create(lib)
  status <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "-l", shQuote(lib), args, shQuote(src)),
    stdout = FALSE,
    stderr = FALSE
  )
  stopifnot(status == 0)
  unlink(src, recursive = TRUE)
  file.path(lib, name)
}

# Don't let the settings of the environment that runs the tests change how
# `package_coverage()` instruments packages.
local_install_defaults <- function(env = parent.frame()) {
  withr::local_envvar(
    COVR_INSTALL_INSTRUMENT = NA,
    .local_envir = env
  )
  withr::local_options(
    covr.install_instrument = NULL,
    .local_envir = env
  )
}
