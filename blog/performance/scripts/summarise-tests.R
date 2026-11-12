# Summarise the type = "tests" benchmark (overnight.sh, results/tests):
# without coverage ("plain"), covr 3.6.5 and covr main, as Markdown.
#
# Times exclude installing the package, which differs by design (covr builds
# with -O0 and its own flags): for plain runs the tests; for covr runs the
# rest of package_coverage(), i.e. the tests plus instrumenting, merging and
# computing the coverage. A covr 3.6.5 run whose tests failed stops with an
# error after the tests; its wall time is used, marked "*".
# Usage: Rscript --no-init-file summarise-tests.R <covr main label> <dir>
args <- commandArgs(trailingOnly = TRUE)
new <- args[[1]]
dir <- args[[2]]
`%||%` <- function(x, y) if (is.null(x)) y else x
wall_time <- function(f) {
  t <- sub("[.]rds$", ".time", f)
  if (!file.exists(t)) return(NA_real_)
  as.numeric(sub(".*wall=", "", grep("wall=", readLines(t, warn = FALSE), value = TRUE)[[1]]))
}
files <- list.files(dir, pattern = "[.]rds$", full.names = TRUE)
runs <- do.call(rbind, lapply(files, function(f) {
  r <- readRDS(f)
  failed <- is.null(r$total) || is.na(r$total)
  # The R process itself adds a few seconds to the wall time of a failed run
  # over package_coverage()'s own time; that is small next to these tests.
  total <- if (failed) wall_time(f) else r$total
  data.frame(
    version = r$label,
    pkg = r$pkg,
    failed = failed,
    tests_failed = isTRUE(r$tests_failed),
    excl_install = if (identical(r$label, "plain")) r$run_code else total - r$install,
    report = r$report %||% NA_real_
  )
}))
fmt <- function(x) ifelse(is.na(x), "—", formatC(x, format = "f", digits = 1, big.mark = ","))
med <- function(p, v) {
  x <- runs[runs$pkg == p & runs$version == v, ]
  if (nrow(x) == 0) return(c(NA, NA))
  c(stats::median(x$excl_install, na.rm = TRUE), any(x$failed))
}
pkgs <- unique(runs$pkg)
plain <- vapply(pkgs, function(p) med(p, "plain")[[1]], 0)
pkgs <- pkgs[order(plain)]
cat("| Package | Without coverage | covr 3.6.5 | covr 4.0.0 | 3.6.5 / without | 4.0.0 / without |\n")
cat("|---|---|---|---|---|---|\n")
for (p in pkgs) {
  a <- med(p, "plain")
  o <- med(p, "3.6.5")
  n <- med(p, new)
  cat(sprintf(
    "| %s | %s s | %s%s | %s s | %s | %s |\n", p,
    fmt(a[[1]]), fmt(o[[1]]), if (isTRUE(o[[2]] == 1)) " s*" else if (is.na(o[[1]])) "" else " s",
    fmt(n[[1]]),
    if (is.na(o[[1]])) "—" else sprintf("%.2f×", o[[1]] / a[[1]]),
    sprintf("%.2f×", n[[1]] / a[[1]])
  ))
}
cat("\nTimes exclude installing the package; median of the runs. * covr 3.6.5 stopped with an error after the tests, as some tests fail; wall time of the run.\n")
tf <- unique(runs$pkg[runs$tests_failed])
if (length(tf)) cat("Packages with failing tests (also without coverage):", paste(sort(tf), collapse = ", "), "\n")
