# A source file with the functions `a()` and `b()`, and a test script calling
# them. The files are removed when the caller's frame exits.
local_ab_files <- function(frame = parent.frame()) {
  list(
    src = withr::local_tempfile(
      lines = c(
        "a <- function(x) {",
        "  x + 1",
        "}",
        "",
        "b <- function(x) {",
        "  if (x > 1) TRUE",
        "  else FALSE",
        "}"
      ),
      .local_envir = frame
    ),
    test = withr::local_tempfile(
      lines = c("a(1)", "a(2)", "a(3)", "b(0)", "b(1)", "b(2)"),
      .local_envir = frame
    )
  )
}
