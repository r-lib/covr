# Summarise the benchmark results as the markdown tables in
# performance-audit.md.
# Usage: Rscript --vanilla performance-audit/summarise.R <bench_dir>
args <- commandArgs(trailingOnly = TRUE)
bench <- if (length(args) >= 1) args[[1]] else "/tmp/covr-bench"
`%||%` <- function(x, y) if (is.null(x)) y else x

out <- file.path(bench, "out")

md_table <- function(df) {
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), "", format(round(x, 1), nsmall = 1, big.mark = ","))
    } else {
      x
    }
  })
  cat("|", paste(names(df), collapse = " | "), "|\n")
  cat("|", paste(rep("---", ncol(df)), collapse = " | "), "|\n")
  for (i in seq_len(nrow(df))) {
    cat("|", paste(df[i, ], collapse = " | "), "|\n")
  }
  cat("\n")
}

read_time <- function(file) {
  if (!file.exists(file)) {
    return(c(maxrss_mb = NA, wall = NA))
  }
  x <- readLines(file, warn = FALSE)
  x <- x[grepl("maxrss_kb=", x)]
  if (!length(x)) {
    return(c(maxrss_mb = NA, wall = NA))
  }
  c(
    maxrss_mb = as.numeric(sub(".*maxrss_kb=([0-9]+).*", "\\1", x)) / 1024,
    wall = as.numeric(sub(".*wall=([0-9.]+).*", "\\1", x))
  )
}

# Cross-version runs -------------------------------------------------------
files <- list.files(
  file.path(out, "versions"),
  pattern = "[.]rds$",
  full.names = TRUE
)
if (length(files)) {
  rows <- lapply(files, function(f) {
    x <- readRDS(f)
    t <- read_time(sub("[.]rds$", ".time", f))
    data.frame(
      r = x$r,
      covr = x$label,
      pkg = x$pkg,
      total = x$total,
      install = x$install,
      run_code = x$run_code,
      merge = x$merge,
      exclude = x$exclude,
      gcov = x$gcov_in_run,
      percent = x$percent %||% NA,
      n_traces = x$n_traces %||% NA,
      percent_coverage = x$percent_coverage %||% NA,
      report = x$report %||% NA,
      maxrss_mb = t[["maxrss_mb"]]
    )
  })
  v <- do.call(rbind, rows)
  v$covr <- factor(v$covr, c("3.5.1", "3.6.0", "3.6.4", "3.6.5", "main"))
  med <- aggregate(
    cbind(total, install, run_code, merge, exclude, maxrss_mb) ~ pkg + r + covr,
    v,
    median,
    na.action = na.pass
  )
  n <- aggregate(total ~ pkg + r + covr, v, length)
  names(n)[4] <- "runs"
  rng <- aggregate(total ~ pkg + r + covr, v, function(x) {
    paste(format(round(sort(x), 1), nsmall = 1), collapse = ", ")
  })
  names(rng)[4] <- "runs (s)"
  pct <- aggregate(
    percent ~ pkg + r + covr,
    v,
    function(x) round(x[[1]], 1),
    na.action = na.pass
  )
  rep1 <- aggregate(
    cbind(report, percent_coverage) ~ pkg + r + covr,
    v,
    function(x) x[!is.na(x)][1],
    na.action = na.pass
  )
  res <- Reduce(
    function(a, b) merge(a, b, all = TRUE),
    list(med, n, rng, pct, rep1)
  )
  res <- res[order(res$pkg, res$r, res$covr), ]
  res$covr <- as.character(res$covr)
  cat("## package_coverage() by covr version (median seconds, wall clock)\n\n")
  md_table(res[, c(
    "pkg",
    "r",
    "covr",
    "runs (s)",
    "total",
    "install",
    "run_code",
    "merge",
    "exclude",
    "percent",
    "maxrss_mb",
    "percent_coverage",
    "report"
  )])
}

# Phases on main ------------------------------------------------------------
files <- list.files(
  file.path(out, "phases"),
  pattern = "-phases[.]rds$",
  full.names = TRUE
)
for (f in files) {
  x <- readRDS(f)
  p <- x$phases
  med <- aggregate(seconds ~ phase, p, median)
  runs <- aggregate(seconds ~ phase, p, function(s) {
    paste(format(round(s, 2), nsmall = 2), collapse = ", ")
  })
  names(runs)[2] <- "runs (s)"
  mem <- aggregate(mem_mb ~ phase, p, median)
  m <- merge(merge(med, runs), mem, all.x = TRUE)
  m <- m[
    order(
      sub(":.*", "", m$phase) != "baseline",
      sub(":.*", "", m$phase) != "covr",
      m$phase
    ),
  ]
  cat(sprintf("## Phases: %s on R %s\n\n", p$pkg[[1]], p$r[[1]]))
  md_table(m)
  str(x$meta)
  cat("\n")
}

# covr on covr ----------------------------------------------------------------
files <- list.files(
  file.path(out, "self"),
  pattern = "[.]time$",
  full.names = TRUE
)
if (length(files)) {
  s <- do.call(
    rbind,
    lapply(files, function(f) {
      x <- strsplit(readLines(f, warn = FALSE)[[1]], " ")[[1]]
      parts <- strsplit(sub("[.]time$", "", basename(f)), "-")[[1]]
      data.frame(
        r = parts[[1]],
        sha = parts[[2]],
        rep = parts[[3]],
        status = x[[1]],
        seconds = as.numeric(x[[2]]),
        maxrss_mb = if (length(x) >= 3) {
          as.numeric(sub("maxrss_kb=", "", x[[3]])) / 1024
        } else {
          NA
        }
      )
    })
  )
  s <- s[s$status == "ok", ]
  med <- aggregate(cbind(seconds, maxrss_mb) ~ r + sha, s, median)
  runs <- aggregate(seconds ~ r + sha, s, function(x) {
    paste(format(round(x, 1), nsmall = 1), collapse = ", ")
  })
  names(runs)[3] <- "runs (s)"
  cat("## covr on covr (median seconds)\n\n")
  md_table(merge(med, runs))
}

# Dev history (Luminescence at commits) ------------------------------------------
files <- list.files(
  file.path(out, "history"),
  pattern = "[.]rds$",
  full.names = TRUE
)
if (length(files)) {
  h <- do.call(
    rbind,
    lapply(files, function(f) {
      x <- readRDS(f)
      t <- read_time(sub("[.]rds$", ".time", f))
      data.frame(
        r = x$r,
        sha = x$label,
        pkg = x$pkg,
        total = x$total,
        install = x$install,
        run_code = x$run_code,
        merge = x$merge,
        exclude = x$exclude,
        gcov = x$gcov_in_run,
        percent_coverage = x$percent_coverage %||% NA,
        report = x$report %||% NA,
        percent = x$percent %||% NA,
        maxrss_mb = t[["maxrss_mb"]]
      )
    })
  )
  med <- aggregate(
    cbind(
      total,
      install,
      run_code,
      merge,
      exclude,
      gcov,
      percent_coverage,
      maxrss_mb
    ) ~ pkg + r + sha,
    h,
    median,
    na.action = na.pass
  )
  rep1 <- aggregate(
    cbind(report, percent) ~ pkg + r + sha,
    h,
    function(x) x[!is.na(x)][1],
    na.action = na.pass
  )
  runs <- aggregate(total ~ pkg + r + sha, h, function(x) {
    paste(format(round(x, 1), nsmall = 1), collapse = ", ")
  })
  names(runs)[4] <- "runs (s)"
  cat("## Development history (median seconds)\n\n")
  md_table(Reduce(
    function(a, b) merge(a, b, all = TRUE),
    list(med, rep1, runs)
  ))
}
