# Size of the trace files package_coverage() writes, with the covr installed
# first in R_LIBS. Trace sizes are deterministic, so one run is enough.
#
# Usage: R_LIBS=$bench/lib/<R>/covr-<sha>:$bench/lib/<R>/deps \
#   <Rscript> --no-init-file performance-audit/trace-size.R <pkg_tarball>
tarball <- normalizePath(commandArgs(trailingOnly = TRUE)[[1]])
pkg <- sub("_.*", "", basename(tarball))
src_dir <- tempfile("src")
dir.create(src_dir)
untar(tarball, exdir = src_dir)
install_path <- tempfile("lib")
code <- sprintf(
  "Sys.setenv(NOT_CRAN = 'true'); testthat::test_dir(system.file('tests/testthat', package = '%s'), package = '%s', load_package = 'installed', reporter = 'silent', stop_on_failure = FALSE, stop_on_warning = FALSE)",
  pkg,
  pkg
)
cov <- covr::package_coverage(
  file.path(src_dir, pkg),
  type = "none",
  code = code,
  clean = FALSE,
  install_path = install_path
)
traces <- list.files(install_path, pattern = "^covr_trace_", full.names = TRUE)
cat(sprintf(
  "covr %s, %s: %d trace files, %.2f MB total, largest %.2f MB\n",
  packageVersion("covr"),
  pkg,
  length(traces),
  sum(file.size(traces)) / 1e6,
  max(file.size(traces)) / 1e6
))
