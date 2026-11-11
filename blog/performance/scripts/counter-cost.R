# Overhead per counted expression of the covr installed first in R_LIBS: a
# loop run under code_coverage(), timed inside the test code (so instrumenting
# isn't counted), minus the same loop uninstrumented, divided by the number of
# counts covr recorded. The loop runs byte-compiled in both cases (the JIT
# compiles it), as in real tests.
# Usage: Rscript --no-init-file counter-cost.R <label> <out.rds>
args <- commandArgs(trailingOnly = TRUE)
label <- args[[1]]
out <- args[[2]]
library(covr)
n <- 2e6
reps <- 5
src <- "f <- function(n) {\n  total <- 0\n  for (i in seq_len(n)) {\n    x <- i * 2\n    total <- total + x\n  }\n  total\n}"
eval(parse(text = src))
f(10)
plain <- stats::median(vapply(seq_len(reps), function(i) system.time(f(n))[["elapsed"]], 0))
runs <- lapply(seq_len(reps), function(i) {
  test <- sprintf("f(10); assign('.elapsed', system.time(f(%d))[['elapsed']], envir = globalenv())", n)
  cov <- code_coverage(src, test)
  list(elapsed = get(".elapsed", envir = globalenv()), counts = sum(as.data.frame(cov)$value))
})
elapsed <- stats::median(vapply(runs, `[[`, 0, "elapsed"))
# Counts of the timed call f(n): 2n + 3 (the warm-up f(10) adds 23); checked
# against what covr recorded.
counts <- 2 * n + 3
stopifnot(runs[[1]]$counts == counts + 23)
res <- list(
  label = label,
  covr = as.character(packageVersion("covr")),
  plain_s = plain,
  instrumented_s = elapsed,
  counts = counts,
  ns_per_count = (elapsed - plain) / counts * 1e9
)
saveRDS(res, out)
cat(sprintf("%s (covr %s): %.0f ns per counted expression (%.0f counts, %.2f s vs %.2f s)\n",
  label, res$covr, res$ns_per_count, counts, elapsed, plain))
