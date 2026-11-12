annotation_coverage <- function() {
  src <- c(
    "f <- function(x) {",
    "  if (x > 0) {",
    "    'positive'",
    "  } else {",
    "    'other'",
    "  }",
    "}",
    "",
    "# a comment",
    "g <- function(x) {",
    "  a <- 1",
    "  b <- 2",
    "  c <- 3",
    "  d <- 4",
    "  e <- 5",
    "  if (x) {",
    "    'never'",
    "  }",
    "  a + b",
    "}"
  )
  code_coverage(paste(src, collapse = "\n"), "f(1); g(FALSE)")
}

scrub_tempfile <- function(x) {
  gsub("^\\S*source\\.R[0-9a-f]+", "source.R", x)
}

many_chunks_coverage <- function(n = 5) {
  # Each function has one missed line, separated by covered code so that every
  # missed line is a chunk of its own with context = 0.
  src <- unlist(lapply(seq_len(n), function(i) {
    c(
      sprintf("f%d <- function(x) {", i),
      "  if (x) {",
      "    'never'",
      "  }",
      "  1",
      "}"
    )
  }))
  code_coverage(
    paste(src, collapse = "\n"),
    paste(sprintf("f%d(FALSE)", seq_len(n)), collapse = "; ")
  )
}
