# Cost of the parse data covr computes in every process that loads an
# instrumented package (get_parse_data() in R/parse_data.R), with and without
# the token text, which covr only uses to find `...` in switch().
#
# Usage: R_LIBS=<covr main lib>:<deps> Rscript --no-init-file \
#   performance-audit/microbench-parse.R <pkg-coverage.rds>

invisible(suppressPackageStartupMessages(loadNamespace("covr")))
cov <- readRDS(commandArgs(trailingOnly = TRUE)[[1]])
lines <- getSrcLines(attr(cov[[1]]$srcref, "srcfile"), 1, Inf)
files <- covr:::split_on_line_directives(lines)
cat(sprintf("%d files, %d lines\n", length(files), length(lines)))

time <- function(label, expr, reps = 3) {
  expr <- substitute(expr)
  env <- parent.frame()
  t <- median(vapply(
    seq_len(reps),
    function(i) system.time(eval(expr, env))[["elapsed"]],
    numeric(1)
  ))
  cat(sprintf("%-60s %7.3f s\n", label, t))
}

parsed <- lapply(files, function(x) parse(text = x, keep.source = TRUE))
time(
  "parse(keep.source = TRUE) of every file",
  lapply(files, function(x) parse(text = x, keep.source = TRUE))
)
time(
  "getParseData(includeText = NA) (current, since #644)",
  lapply(parsed, getParseData, includeText = NA)
)
time(
  "getParseData(includeText = TRUE) (before #644)",
  lapply(parsed, getParseData, includeText = TRUE)
)
time(
  "getParseData(includeText = FALSE)",
  lapply(parsed, getParseData, includeText = FALSE)
)
