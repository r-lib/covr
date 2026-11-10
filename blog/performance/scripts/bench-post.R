# Time covr's post-processing functions on a saved coverage object, with the
# covr installed first in R_LIBS. Network functions are timed through their
# payload builders, without uploading.
# Usage: Rscript --no-init-file bench-post.R <coverage.rds> <label> [reps]
args <- commandArgs(trailingOnly = TRUE)
cov <- readRDS(args[[1]])
label <- args[[2]]
reps <- if (length(args) >= 3) as.integer(args[[3]]) else 3L
suppressPackageStartupMessages(library(covr))
ns <- asNamespace("covr")
has <- function(f) exists(f, envir = ns, inherits = FALSE)
tmp <- tempfile()
dir.create(tmp)
old <- setwd(tmp)
on.exit(setwd(old))

cases <- list(
  print = function() capture.output(print(cov)),
  print_functions = function() capture.output(print(cov, group = "functions")),
  percent_coverage = function() percent_coverage(cov),
  tally_coverage = function() tally_coverage(cov),
  zero_coverage = function() zero_coverage(cov),
  as.data.frame = function() as.data.frame(cov),
  report = function() report(cov, file = file.path(tmp, "r.html"), browse = FALSE),
  to_cobertura = function() to_cobertura(cov, filename = file.path(tmp, "c.xml")),
  to_sonarqube = function() to_sonarqube(cov, filename = file.path(tmp, "s.xml")),
  to_codecov = function() ns$to_codecov(cov),
  to_coveralls = function() ns$to_coveralls(cov),
  to_lcov = if (has("to_lcov")) function() to_lcov(cov, filename = file.path(tmp, "l.info")),
  annotate_coverage = if (has("annotate_coverage")) function() capture.output(annotate_coverage(cov)),
  print_missing = if (has("annotate_coverage")) function() capture.output(print(cov, missing = TRUE))
)
cases <- Filter(Negate(is.null), cases)
res <- do.call(rbind, lapply(names(cases), function(nm) {
  f <- cases[[nm]]
  t <- vapply(seq_len(reps), function(i) {
    gc()
    tryCatch(system.time(suppressMessages(suppressWarnings(f())))[["elapsed"]], error = function(e) {
      message(nm, ": ", conditionMessage(e))
      NA_real_
    })
  }, numeric(1))
  data.frame(label = label, fn = nm, median = stats::median(t), min = min(t))
}))
print(res, row.names = FALSE)
saveRDS(res, sprintf("%s/post-%s.rds", dirname(normalizePath(args[[1]], mustWork = TRUE)), label))
