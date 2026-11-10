# Plot covr 3.6.5 vs 4.0.0 benchmark results as a dumbbell plot per package,
# for package_coverage() and report().
# Usage: Rscript --no-init-file plot-release.R <new label> <out.png> <dir>...
args <- commandArgs(trailingOnly = TRUE)
new <- args[[1]]
out <- args[[2]]
dirs <- args[-(1:2)]
suppressPackageStartupMessages(library(ggplot2))
`%||%` <- function(x, y) if (is.null(x)) y else x
files <- unlist(lapply(dirs, list.files, pattern = "[.]rds$", full.names = TRUE))
runs <- do.call(rbind, lapply(files, function(f) {
  r <- readRDS(f)
  data.frame(
    version = r$label,
    pkg = r$pkg,
    total = r$total,
    until_failure = r$install + r$run_code + r$merge,
    report = r$report %||% NA_real_
  )
}))
runs <- runs[runs$version %in% c("3.6.5", new), ]
runs$version <- ifelse(runs$version == new, "4.0.0", "3.6.5")
summ <- do.call(rbind, lapply(split(runs, list(runs$pkg, runs$version), drop = TRUE), function(x) {
  failed <- all(is.na(x$total))
  data.frame(
    pkg = x$pkg[[1]],
    version = x$version[[1]],
    failed = failed,
    coverage = if (failed) stats::median(x$until_failure) else stats::median(x$total, na.rm = TRUE),
    report = stats::median(x$report, na.rm = TRUE)
  )
}))
# Only packages measured with both versions.
both <- names(which(table(summ$pkg) == 2))
summ <- summ[summ$pkg %in% both, ]
ord <- summ[summ$version == "3.6.5", ]
summ$pkg <- factor(summ$pkg, levels = ord$pkg[order(ord$coverage)])

long <- rbind(
  data.frame(summ[, c("pkg", "version", "failed")], step = "package_coverage()", seconds = summ$coverage),
  data.frame(summ[, c("pkg", "version", "failed")], step = "report()", seconds = summ$report)
)
long <- long[!is.na(long$seconds), ]
long$failed[long$step == "report()"] <- FALSE
long$step <- factor(long$step, levels = c("package_coverage()", "report()"))
wide <- reshape(long[, c("pkg", "step", "version", "seconds")], idvar = c("pkg", "step"), timevar = "version", direction = "wide")
wide <- wide[stats::complete.cases(wide), ]

cols <- c("3.6.5" = "#E69F00", "4.0.0" = "#0072B2")
p <- ggplot(long, aes(seconds, pkg)) +
  geom_segment(data = wide, aes(x = seconds.3.6.5, xend = seconds.4.0.0, y = pkg, yend = pkg), colour = "grey70", linewidth = 1) +
  geom_point(data = long[!long$failed, ], aes(colour = version), size = 2.6) +
  geom_point(data = long[long$failed, ], aes(colour = version), shape = 4, size = 3, stroke = 1.3) +
  geom_text(data = long[long$failed, ], aes(label = "failed", colour = version), hjust = -0.35, size = 3, show.legend = FALSE) +
  scale_x_log10(
    breaks = c(0.1, 0.3, 1, 3, 10, 30, 60, 120, 300, 600),
    labels = c("0.1s", "0.3s", "1s", "3s", "10s", "30s", "1m", "2m", "5m", "10m"),
    expand = expansion(mult = c(0.05, 0.15))
  ) +
  scale_colour_manual(values = cols, name = "covr") +
  guides(colour = guide_legend(override.aes = list(shape = 16, size = 3))) +
  facet_wrap(~step, scales = "free_x") +
  labs(x = "Time (log scale)", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", panel.grid.minor = element_blank(), panel.grid.major.y = element_line(colour = "grey92"))
ggsave(out, p, width = 9, height = 0.32 * length(both) + 1.6, dpi = 150, bg = "white")
cat("wrote", out, "with", length(both), "packages\n")
