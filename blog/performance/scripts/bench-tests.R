# Time package_coverage() of a source tarball with its own tests (type =
# "tests"), using the covr installed first in R_LIBS.
# Usage: Rscript --no-init-file bench-tests.R <tarball> <label> <out.rds>
args <- commandArgs(trailingOnly = TRUE)
tarball <- normalizePath(args[[1]])
label <- args[[2]]
out <- args[[3]]
pkg <- sub("_.*", "", basename(tarball))
src_dir <- tempfile("src")
dir.create(src_dir)
untar(tarball, exdir = src_dir)
Sys.setenv(NOT_CRAN = "true")
invisible(loadNamespace("covr"))
t0 <- proc.time()[["elapsed"]]
cov <- tryCatch(
  suppressWarnings(covr::package_coverage(
    file.path(src_dir, pkg),
    type = "tests",
    quiet = TRUE,
    allow_failures = TRUE
  )),
  error = function(e) {
    message("error: ", conditionMessage(e))
    NULL
  }
)
total <- proc.time()[["elapsed"]] - t0
res <- list(
  label = label,
  pkg = pkg,
  total = total,
  ok = !is.null(cov),
  n_traces = length(cov),
  percent = if (!is.null(cov)) covr::percent_coverage(cov) else NA,
  values = if (!is.null(cov)) {
    vapply(unclass(cov), function(x) as.numeric(x$value), numeric(1))
  }
)
saveRDS(res, out)
cat(sprintf("%s %s: %.1f s, %d traces, %.2f%%\n", label, pkg, total, res$n_traces, res$percent))
