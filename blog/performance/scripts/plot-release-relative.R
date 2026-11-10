# Plot covr 4.0.0's time as a percentage of covr 3.6.5's for each package, for
# package_coverage() and report(), labelled with the absolute times.
# Usage: Rscript --no-init-file plot-release-relative.R <new label> <out.png> <dir>...
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
runs$version <- ifelse(runs$version == new, "new", "old")
med <- function(x) if (all(is.na(x))) NA_real_ else stats::median(x, na.rm = TRUE)
summ <- do.call(rbind, lapply(split(runs, runs$pkg), function(x) {
  old <- x[x$version == "old", ]
  new <- x[x$version == "new", ]
  if (nrow(old) == 0 || nrow(new) == 0) return(NULL)
  rbind(
    data.frame(
      pkg = x$pkg[[1]], step = "package_coverage()",
      old = med(old$total), new = med(new$total),
      old_failed_after = if (all(is.na(old$total))) med(old$until_failure) else NA_real_,
      new_failed = all(is.na(new$total))
    ),
    data.frame(
      pkg = x$pkg[[1]], step = "report()",
      old = med(old$report), new = med(new$report),
      old_failed_after = NA_real_, new_failed = FALSE
    )
  )
}))
# Both times of a row in minutes when both are 2 minutes or more, mixed when
# they differ by orders of magnitude (e.g. 5.8m -> 3.2s), else in seconds, so a
# row never reads like 96s -> 1.5m or 5.8m -> 0.1m.
fmt_pair <- function(old, new) {
  secs <- function(s) ifelse(s < 10, sprintf("%.1fs", s), sprintf("%.0fs", s))
  mins <- function(s) sprintf("%.1fm", s / 60)
  both_min <- old >= 120 & new >= 120
  mixed <- old >= 120 & new < 10
  sprintf(
    "%s \u2192 %s",
    ifelse(both_min | mixed, mins(old), secs(old)),
    ifelse(both_min, mins(new), secs(new))
  )
}
fmt_time <- function(s) ifelse(s >= 120, sprintf("%.1fm", s / 60), sprintf("%.0fs", s))
summ$pct <- 100 * summ$new / summ$old
summ$label <- ifelse(
  !is.na(summ$pct),
  fmt_pair(summ$old, summ$new),
  ifelse(!is.na(summ$old_failed_after),
    sprintf("3.6.5 fails after %s; 4.0.0 takes %s", fmt_time(summ$old_failed_after), fmt_time(summ$new)),
    ifelse(summ$new_failed, "4.0.0 fails", NA_character_)))
summ <- summ[!is.na(summ$label), ]
# Order packages by 3.6.5 package_coverage() time (or time until it failed).
key <- summ[summ$step == "package_coverage()", ]
key$t <- ifelse(is.na(key$old), key$old_failed_after, key$old)
summ$pkg <- factor(summ$pkg, levels = key$pkg[order(key$t)])
summ$step <- factor(summ$step, levels = c("package_coverage()", "report()"))

p <- ggplot(summ, aes(y = pkg)) +
  # The 100% reference only on rows with a bar, so it doesn't cross the text
  # of the rows where a version failed.
  geom_errorbar(
    aes(xmin = 100, xmax = 100), data = summ[!is.na(summ$pct), ],
    width = 1, colour = "grey60", linetype = "dashed", orientation = "y"
  ) +
  geom_col(aes(x = pct), data = summ[!is.na(summ$pct), ], fill = "#0072B2", width = 0.7, orientation = "y") +
  geom_text(aes(x = ifelse(is.na(pct), 0, pct), label = label), hjust = -0.05, size = 3, colour = "grey20") +
  scale_x_continuous(
    limits = c(0, 175), breaks = c(0, 25, 50, 75, 100),
    labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0, 0))
  ) +
  facet_wrap(~step) +
  labs(x = "Time with covr 4.0.0, as a percentage of the time with covr 3.6.5", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank())
ggsave(out, p, width = 10, height = 0.32 * nlevels(summ$pkg) + 1.4, dpi = 150, bg = "white")
cat("wrote", out, "with", nlevels(summ$pkg), "packages\n")
