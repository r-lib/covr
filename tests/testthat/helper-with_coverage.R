local_fixture_env <- function(frame = parent.frame()) {
  src <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(
    c(
      "add <- function(x, y) {",
      "  if (x > 0) {",
      "    x + y",
      "  } else {",
      "    y",
      "  }",
      "}"
    ),
    src
  )
  env <- new.env(parent = globalenv())
  sys.source(src, envir = env, keep.source = TRUE)
  attr(env, "src") <- src
  env
}

normalize_coverage <- function(x) {
  df <- as.data.frame(x)
  df$filename <- basename(df$filename)
  df <- df[
    order(df$filename, df$first_line, df$first_byte),
    c("filename", "functions", "first_line", "last_line", "value")
  ]
  rownames(df) <- NULL
  df
}

local_load_all <- function(pkg, frame = parent.frame()) {
  pkgload::load_all(test_path(pkg), quiet = TRUE, export_all = TRUE)
  withr::defer(pkgload::unload(pkg), envir = frame)
  asNamespace(pkg)
}

fixture_test_file <- function(pkg) {
  list.files(
    test_path(pkg, "tests", "testthat"),
    "^test.*\\.R$",
    full.names = TRUE
  )
}

# Run a fixture's test file, capturing what its tests print
quiet_test_file <- function(pkg, ...) {
  utils::capture.output(
    res <- testthat::test_file(
      fixture_test_file(pkg),
      package = pkg,
      reporter = "silent",
      ...
    )
  )
  invisible(res)
}
