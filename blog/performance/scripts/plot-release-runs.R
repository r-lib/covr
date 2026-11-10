# Plot every package_coverage() run of covr 3.6.5 and 4.0.0 as a dot, per
# package, on a linear time axis, for packages taking at least MIN_SECONDS
# (default 30) with 3.6.5. Packages that failed with either version are left
# out (the post covers them in text). Each row is labelled with the change in
# median time, or "within noise" when the slowest 4.0.0 run is no faster than
# the fastest 3.6.5 run.
# Usage: Rscript --no-init-file plot-release-runs.R <new label> <out.png> <dir>...
args <- commandArgs(trailingOnly = TRUE)
new <- args[[1]]
out <- args[[2]]
dirs <- args[-(1:2)]
min_seconds <- as.numeric(Sys.getenv("MIN_SECONDS", "30"))
suppressPackageStartupMessages(library(ggplot2))
files <- unlist(lapply(dirs, list.files, pattern = "[.]rds$", full.names = TRUE))
runs <- do.call(rbind, lapply(files, function(f) {
  r <- readRDS(f)
  data.frame(version = r$label, pkg = r$pkg, total = r$total)
}))
runs <- runs[runs$version %in% c("3.6.5", new), ]
runs$version <- factor(ifelse(runs$version == new, "4.0.0", "3.6.5"), levels = c("3.6.5", "4.0.0"))
ok <- tapply(runs$total, list(runs$pkg, runs$version), function(x) all(!is.na(x)))
keep <- rownames(ok)[ok[, "3.6.5"] & ok[, "4.0.0"] & !is.na(ok[, "3.6.5"]) & !is.na(ok[, "4.0.0"])]
runs <- runs[runs$pkg %in% keep, ]
summ <- do.call(rbind, lapply(split(runs, runs$pkg), function(x) {
  o <- x$total[x$version == "3.6.5"]
  n <- x$total[x$version == "4.0.0"]
  data.frame(
    pkg = x$pkg[[1]], old = stats::median(o), new = stats::median(n),
    noise = max(n) >= min(o)
  )
}))
small <- summ[summ$old < min_seconds, ]
summ <- summ[summ$old >= min_seconds, ]
summ$saved <- summ$old - summ$new
summ$label <- ifelse(summ$noise, "within noise", sprintf("\u2212%.0f%%", 100 * (1 - summ$new / summ$old)))
levels <- summ$pkg[order(summ$saved)]
runs <- runs[runs$pkg %in% summ$pkg, ]
runs$pkg <- factor(runs$pkg, levels = levels)
summ$pkg <- factor(summ$pkg, levels = levels)
xmax <- max(runs$total)
cols <- c("3.6.5" = "#E69F00", "4.0.0" = "#0072B2")

p <- ggplot(runs, aes(total, pkg)) +
  geom_segment(data = summ, aes(x = new, xend = old, y = pkg, yend = pkg), colour = "grey65", linewidth = 0.8) +
  geom_point(aes(colour = version), size = 2.8, alpha = 0.8) +
  geom_text(data = summ, aes(x = xmax * 1.04, y = pkg, label = label), hjust = 0, size = 3.6, colour = "grey20") +
  scale_x_continuous(
    limits = c(0, xmax * 1.22), breaks = seq(0, xmax, by = 60),
    labels = function(x) paste(x, "s"), expand = expansion(mult = c(0, 0))
  ) +
  scale_colour_manual(values = cols, name = NULL, labels = c("covr 3.6.5", "covr 4.0.0 (each dot is a run)")) +
  labs(x = "package_coverage() time", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top", legend.justification = "left", panel.grid.minor = element_blank())
ggsave(out, p, width = 7, height = 0.38 * length(levels) + 1.4, dpi = 150, bg = "white")
cat("wrote", out, "with", length(levels), "packages; under", min_seconds, "s:",
  paste(sprintf("%s %.0f -> %.0f s", small$pkg, small$old, small$new), collapse = ", "), "\n")
