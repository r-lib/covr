# Summarise the runs of run-release.sh as the Markdown tables in README.md.
# Usage: Rscript --no-init-file summarise-release.R <new label> <dir>...
# e.g. summarise-release.R 1a2b3c4 results/release results/release-tests
# A run that failed is shown as "fails after <s>": the time of the install,
# the tests and merging the coverage, until the failure.
args <- commandArgs(trailingOnly = TRUE)
new <- args[[1]]
dirs <- args[-1]
`%||%` <- function(x, y) if (is.null(x)) y else x
files <- unlist(lapply(dirs, list.files, pattern = "[.]rds$", full.names = TRUE))
runs <- do.call(rbind, lapply(files, function(f) {
  r <- readRDS(f)
  data.frame(
    version = r$label,
    pkg = r$pkg,
    total = r$total,
    until_failure = r$install + r$run_code + r$merge,
    report = r$report %||% NA_real_,
    mem = r$main_mem_after_post_mb,
    percent = r$percent %||% NA_real_
  )
}))
runs <- runs[runs$version %in% c("3.6.5", new), ]
fmt <- function(x) formatC(x, format = "f", digits = 1, big.mark = ",")
sel <- function(p, v) runs[runs$pkg == p & runs$version == v, ]
time_cell <- function(p, v) {
  x <- sel(p, v)
  if (nrow(x) == 0) return("—")
  if (all(is.na(x$total))) return(sprintf("fails after %s s", fmt(stats::median(x$until_failure))))
  paste0(fmt(stats::median(x$total, na.rm = TRUE)), " s")
}
med <- function(p, v, col) stats::median(sel(p, v)[[col]], na.rm = TRUE)
mem_cell <- function(p, v) {
  m <- sel(p, v)
  m <- m$mem[!is.na(m$report)]
  if (length(m) == 0) "—" else paste(formatC(round(max(m)), format = "d", big.mark = ","), "MB")
}
pkgs <- unique(runs$pkg[runs$version == new])
order_key <- vapply(pkgs, function(p) {
  x <- sel(p, "3.6.5")
  if (nrow(x) == 0) Inf else stats::median(ifelse(is.na(x$total), x$until_failure, x$total))
}, numeric(1))
pkgs <- pkgs[order(order_key)]

cat("| Package | covr 3.6.5 | covr 4.0.0 | Speedup | Runs |\n|---|---|---|---|---|\n")
for (p in pkgs) {
  a <- med(p, "3.6.5", "total")
  b <- med(p, new, "total")
  speed <- if (is.na(a) || is.na(b)) "—" else sprintf("%.1fx", a / b)
  cat(sprintf("| %s | %s | %s | %s | %d |\n", p, time_cell(p, "3.6.5"), time_cell(p, new), speed, nrow(sel(p, new))))
}
cat("\n| Package | `report()` 3.6.5 | `report()` 4.0.0 | Peak memory 3.6.5 | Peak memory 4.0.0 |\n|---|---|---|---|---|\n")
for (p in pkgs) {
  rep_cell <- function(v) {
    x <- med(p, v, "report")
    if (is.na(x)) "—" else paste0(fmt(x), " s")
  }
  cat(sprintf("| %s | %s | %s | %s | %s |\n", p, rep_cell("3.6.5"), rep_cell(new), mem_cell(p, "3.6.5"), mem_cell(p, new)))
}
cat("\nIndividual runs (seconds of `package_coverage()`; NA = failed):\n\n")
for (p in pkgs) {
  for (v in c("3.6.5", new)) {
    x <- sel(p, v)
    if (nrow(x) == 0) next
    pct <- unique(round(x$percent[!is.na(x$percent)], 1))
    cat(sprintf("- %s, %s: %s (coverage %s)\n", p, v, paste(fmt(x$total), collapse = ", "),
      if (length(pct)) paste0(paste(fmt(pct), collapse = "/"), "%") else "none"))
  }
}
