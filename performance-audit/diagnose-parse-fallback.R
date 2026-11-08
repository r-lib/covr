# How often instrumenting a package falls back from covr's cached per-file
# parse data (get_parse_data()) to utils::getParseData(srcref), which on
# R >= 4.4 computes the parse data of the whole package on every call (#567).
#
# Usage: R_LIBS=<covr main lib>:<deps> Rscript --no-init-file \
#   performance-audit/diagnose-parse-fallback.R <pkg_tarball>

invisible(suppressPackageStartupMessages(loadNamespace("covr")))
tarball <- normalizePath(commandArgs(trailingOnly = TRUE)[[1]])
pkg_name <- sub("_.*", "", basename(tarball))
src_dir <- tempfile("src")
dir.create(src_dir)
untar(tarball, exdir = src_dir)
pkg <- covr:::as_package(file.path(src_dir, pkg_name))
lib <- tempfile("instr")
dir.create(lib)
covr:::install_package(pkg, lib, getOption("covr.flags"), quiet = TRUE)
covr:::add_hooks(pkg$package, lib)

child <- tempfile(fileext = ".R")
writeLines(
  c(
    "loadNamespace('covr')",
    "calls <- new.env()",
    "calls$n <- 0; calls$seconds <- 0; calls$files <- character()",
    "trace('get_tokens', where = asNamespace('covr'), print = FALSE,",
    "  tracer = quote({",
    "    .t0 <- proc.time()[[3]]",
    "    .cached <- covr:::get_parse_data(attr(getSrcref(srcref), 'srcfile'))",
    "    .fallback <- is.null(.cached)",
    "    if (.fallback) calls$files <- c(calls$files, attr(getSrcref(srcref), 'srcfile')$filename)",
    "  }),",
    "  exit = quote(if (.fallback) {",
    "    calls$n <- calls$n + 1",
    "    calls$seconds <- calls$seconds + proc.time()[[3]] - .t0",
    "  }))",
    "t0 <- proc.time()[[3]]",
    sprintf("suppressPackageStartupMessages(loadNamespace('%s'))", pkg_name),
    "cat(sprintf('load + trace_environment(): %.2f s\\n', proc.time()[[3]] - t0))",
    "cat(sprintf('getParseData(srcref) fallbacks: %d calls, %.2f s\\n', calls$n, calls$seconds))",
    "print(utils::head(sort(table(calls$files), decreasing = TRUE), 10))"
  ),
  child
)
scratch <- tempfile("scratch")
dir.create(scratch)
system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(child)),
  env = c(
    paste0(
      "R_LIBS=",
      paste(c(lib, strsplit(Sys.getenv("R_LIBS"), ":")[[1]]), collapse = ":")
    ),
    "R_COVR=true",
    paste0("COVERAGE_DIR=", scratch)
  )
)
