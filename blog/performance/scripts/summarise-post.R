# Summarise the results of run-post.sh: the median time of each function with
# covr 3.6.5 and covr main for each package, and the median speedup of each
# function across packages. Writes summary.md next to the results.
# Usage: Rscript --no-init-file summarise-post.R [results/tests/post]
args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args)) args[[1]] else file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))), "..", "results", "tests", "post")
sha <- readLines(file.path(dir, "covr-sha"))
res <- do.call(rbind, lapply(list.files(dir, "[.]rds$", full.names = TRUE), readRDS))
res$label[res$label == sha] <- "main"
wide <- reshape(res[c("label", "pkg", "fn", "median")], idvar = c("pkg", "fn"), timevar = "label", direction = "wide")
wide <- wide[stats::complete.cases(wide), ]
wide$speedup <- wide$median.3.6.5 / wide$median.main

fmt <- function(x) ifelse(x < 1, sprintf("%.2f s", x), sprintf("%.1f s", x))
by_fn <- aggregate(speedup ~ fn, wide, function(x) c(median = stats::median(x), min = min(x), max = max(x)))
by_fn <- data.frame(fn = by_fn$fn, by_fn$speedup)
by_fn <- by_fn[order(-by_fn$median), ]

out <- c(
  sprintf("Median time of bench::mark() runs, covr 3.6.5 vs covr main (%s), %d packages.", sha, length(unique(wide$pkg))),
  "",
  "| Function | Median speedup | Range |",
  "|---|---|---|",
  sprintf("| `%s` | %.1f× | %.1f×–%.1f× |", by_fn$fn, by_fn$median, by_fn$min, by_fn$max),
  "",
  sprintf("Median speedup over all functions and packages: %.1f×", stats::median(wide$speedup)),
  "",
  "| Package | Function | covr 3.6.5 | covr main | Speedup |",
  "|---|---|---|---|---|"
)
wide <- wide[order(wide$pkg, wide$fn), ]
out <- c(out, sprintf("| %s | `%s` | %s | %s | %.1f× |", wide$pkg, wide$fn, fmt(wide$median.3.6.5), fmt(wide$median.main), wide$speedup))
writeLines(out, file.path(dir, "summary.md"))
writeLines(out[1:(length(by_fn$fn) + 7)])
