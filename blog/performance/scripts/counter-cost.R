# Overhead per counted expression of the covr installed first in R_LIBS:
# the time of a byte-compiled loop measured with function_coverage(), minus the
# same loop uninstrumented, divided by the number of counts covr recorded.
# Usage: Rscript --no-init-file counter-cost.R <label> <out.rds>
args <- commandArgs(trailingOnly = TRUE)
label <- args[[1]]
out <- args[[2]]
library(covr)
n <- 2e6
f <- function(n) {
  total <- 0
  for (i in seq_len(n)) {
    x <- i * 2
    total <- total + x
  }
  total
}
f <- compiler::cmpfun(f)
time <- function(expr) system.time(expr)[["elapsed"]]
reps <- 5
plain <- median(vapply(seq_len(reps), function(i) time(f(n)), 0))
runs <- lapply(seq_len(reps), function(i) {
  elapsed <- time(cov <- function_coverage(f, f(n)))
  list(elapsed = elapsed, counts = sum(as.data.frame(cov)$value))
})
elapsed <- median(vapply(runs, `[[`, 0, "elapsed"))
counts <- runs[[1]]$counts
res <- list(
  label = label,
  covr = as.character(packageVersion("covr")),
  plain_s = plain,
  instrumented_s = elapsed,
  counts = counts,
  ns_per_count = (elapsed - plain) / counts * 1e9
)
saveRDS(res, out)
cat(sprintf("%s (covr %s): %.0f ns per counted expression (%d counts, %.2f s vs %.2f s)\n",
  label, res$covr, res$ns_per_count, counts, elapsed, plain))
