# Print the top functions of an Rprof() profile by self and total time.
# Usage: Rscript performance-audit/summarise-profile.R <file.Rprof> [n]
args <- commandArgs(trailingOnly = TRUE)
n <- if (length(args) >= 2) as.integer(args[[2]]) else 25L
s <- summaryRprof(args[[1]])
cat(sprintf("sampling time: %.2f s\n\nby self:\n", s$sampling.time))
print(utils::head(s$by.self, n))
cat("\nby total:\n")
print(utils::head(s$by.total, n))
