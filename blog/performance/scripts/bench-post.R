# Time covr's post-processing functions on a saved coverage object with
# bench::mark(), using the covr installed first in R_LIBS. Exporters that
# upload are timed through their payload builders, without uploading.
# report() is left out: run 1 of the overnight benchmark already times it.
# Usage: Rscript --no-init-file bench-post.R <coverage.rds> <label> <out.rds> [iterations]
args <- commandArgs(trailingOnly = TRUE)
cov <- readRDS(args[[1]])
label <- args[[2]]
out <- args[[3]]
iterations <- if (length(args) >= 4) as.integer(args[[4]]) else 5L
suppressPackageStartupMessages(library(covr))
ns <- asNamespace("covr")
# The exporters were renamed in 4.0.0 (#750), and their output argument from
# `filename` to `file`; use whichever this covr has, passing the path second.
fn <- function(new, old) {
  if (exists(new, envir = ns, inherits = FALSE)) get(new, envir = ns) else get(old, envir = ns)
}
cobertura_fn <- fn("cobertura", "to_cobertura")
sonarqube_fn <- fn("sonarqube", "to_sonarqube")
quiet <- function(x) suppressMessages(suppressWarnings(x))
tmp <- tempfile()

res <- bench::mark(
  tally_coverage = tally_coverage(cov),
  percent_coverage = percent_coverage(cov),
  zero_coverage = quiet(zero_coverage(cov)),
  print = quiet(utils::capture.output(print(cov), type = "message")),
  codecov = ns$to_codecov(cov),
  cobertura = cobertura_fn(cov, tmp),
  sonarqube = sonarqube_fn(cov, tmp),
  iterations = iterations,
  check = FALSE,
  filter_gc = FALSE,
  memory = FALSE
)
df <- data.frame(
  label = label,
  pkg = sub("^[^-]+-(.*)[.]rds$", "\\1", basename(args[[1]])),
  fn = as.character(res$expression),
  median = as.numeric(res$median),
  min = as.numeric(res$min)
)
saveRDS(df, out)
print(df[, c("fn", "median", "min")], row.names = FALSE, digits = 3)
