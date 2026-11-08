is_r_devel <- function() {
  startsWith(R.version$status, "Under development")
}

is_win_r41 <- function() {
  x <- getRversion()
  is_windows() && x$major == 4 && x$minor == 1
}

<<<<<<< HEAD
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
=======
local_r_file <- function(lines, frame = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(lines, path)
  path
>>>>>>> bd869a7 (Only trace functions that are not traced yet when tracing an environment again)
}
