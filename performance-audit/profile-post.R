# Profile covr's post-processing of a coverage object saved by bench-phases.R.
# Usage: R_LIBS=<covr main lib>:<deps> Rscript --no-init-file \
#   performance-audit/profile-post.R <pkg-coverage.rds> <out_prefix>
args <- commandArgs(trailingOnly = TRUE)
cov <- readRDS(args[[1]])
prefix <- args[[2]]
invisible(suppressPackageStartupMessages(loadNamespace("covr")))
steps <- list(
  report = function() {
    covr::report(cov, file = tempfile(fileext = ".html"), browse = FALSE)
  },
  cobertura = function() {
    covr::cobertura(cov, filename = tempfile(fileext = ".xml"))
  },
  print = function() utils::capture.output(print(cov)),
  tally_coverage = function() covr::tally_coverage(cov),
  percent_coverage = function() covr::percent_coverage(cov)
)
for (name in names(steps)) {
  file <- paste0(prefix, "-", name, ".Rprof")
  Rprof(file, interval = 0.01)
  t <- system.time(steps[[name]]())[["elapsed"]]
  Rprof(NULL)
  s <- summaryRprof(file)
  cat(sprintf("\n== %s: %.2f s\nby self:\n", name, t))
  print(utils::head(s$by.self, 12))
  cat("by total:\n")
  print(utils::head(s$by.total, 20))
}
