# Plot every run of the type = "tests" benchmark as a dot, per package, on a
# linear time axis: without coverage ("plain"), covr 3.6.5 and covr main.
# Times exclude installing the package (see summarise-tests.R). A covr 3.6.5
# run that stopped with an error after the tests (failing tests) is drawn at
# its wall time minus the install, like the others.
#
# Packages are shown when their median covr 3.6.5 time is between MIN_SECONDS
# (default 30) and MAX_SECONDS (default 300); the others are printed for the
# caption. Each row is labelled with covr 4.0.0's time relative to running the
# tests without coverage.
# Usage: Rscript --no-init-file plot-release-runs.R <covr main label> <out.png> <dir>
args <- commandArgs(trailingOnly = TRUE)
new <- args[[1]]
out <- args[[2]]
dir <- args[[3]]
min_seconds <- as.numeric(Sys.getenv("MIN_SECONDS", "30"))
max_seconds <- as.numeric(Sys.getenv("MAX_SECONDS", "300"))
suppressPackageStartupMessages(library(ggplot2))
wall_time <- function(f) {
  t <- sub("[.]rds$", ".time", f)
  if (!file.exists(t)) return(NA_real_)
  as.numeric(sub(".*wall=", "", grep("wall=", readLines(t, warn = FALSE), value = TRUE)[[1]]))
}
files <- list.files(dir, pattern = "[.]rds$", full.names = TRUE)
runs <- do.call(rbind, lapply(files, function(f) {
  r <- readRDS(f)
  failed <- is.null(r$total) || is.na(r$total)
  total <- if (failed) wall_time(f) else r$total
  data.frame(
    version = r$label, pkg = r$pkg,
    seconds = if (identical(r$label, "plain")) r$run_code else total - r$install
  )
}))
labels <- c(plain = "without coverage", "3.6.5" = "covr 3.6.5", new = "covr 4.0.0")
names(labels)[3] <- new
runs <- runs[runs$version %in% names(labels) & !is.na(runs$seconds), ]
runs$version <- factor(labels[runs$version], levels = labels)
med <- function(p, v) stats::median(runs$seconds[runs$pkg == p & runs$version == v])
pkgs <- unique(runs$pkg)
summ <- data.frame(
  pkg = pkgs,
  plain = vapply(pkgs, med, 0, v = labels[["plain"]]),
  old = vapply(pkgs, med, 0, v = labels[["3.6.5"]]),
  new = vapply(pkgs, med, 0, v = labels[[new]])
)
shown <- !is.na(summ$old) & summ$old >= min_seconds & summ$old <= max_seconds
other <- summ[!shown, ]
summ <- summ[shown, ]
summ$label <- sprintf("+%.0f%%", 100 * (summ$new / summ$plain - 1))
levels <- summ$pkg[order(summ$old - summ$new)]
runs <- runs[runs$pkg %in% summ$pkg, ]
runs$pkg <- factor(runs$pkg, levels = levels)
summ$pkg <- factor(summ$pkg, levels = levels)
xmax <- max(runs$seconds)
cols <- stats::setNames(c("grey55", "#E69F00", "#0072B2"), labels)

p <- ggplot(runs, aes(seconds, pkg)) +
  geom_segment(data = summ, aes(x = new, xend = old, y = pkg, yend = pkg), colour = "grey75", linewidth = 0.8) +
  geom_point(aes(colour = version, shape = version), size = 2.8, alpha = 0.85) +
  geom_text(data = summ, aes(x = xmax * 1.04, y = pkg, label = label), hjust = 0, size = 3.6, colour = "grey20") +
  scale_x_continuous(
    limits = c(0, xmax * 1.18), breaks = seq(0, xmax, by = 60),
    labels = function(x) ifelse(x == 0, "0", paste(x / 60, "min")), expand = expansion(mult = c(0, 0))
  ) +
  scale_colour_manual(values = cols, name = NULL) +
  scale_shape_manual(values = stats::setNames(c(17, 16, 16), labels), name = NULL) +
  labs(x = "Time to run the tests (each mark is a run)", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top", legend.justification = "left", panel.grid.minor = element_blank())
ggsave(out, p, width = 7.5, height = 0.38 * length(levels) + 1.5, dpi = 150, bg = "white")
fmt <- function(x) ifelse(is.na(x), "fails", sprintf("%.0f s", x))
cat("wrote", out, "with", length(levels), "packages; in the caption instead (without / 3.6.5 / 4.0.0):\n",
  paste(sprintf("%s %s / %s / %s", other$pkg, fmt(other$plain), fmt(other$old), fmt(other$new)), collapse = "; "), "\n")
