#!/bin/sh
# The final covr 3.6.5 vs 4.0.0 benchmarks for the release blog post, run
# sequentially overnight. Build <bench> first with setup-release.sh.
#
# Every result is written straight to results/final in this repository, so a
# crash or reboot loses at most the run in progress. Rerunning the script
# resumes: finished runs are skipped, and the covr main commit chosen by the
# first start (results/final/covr-sha) is reused.
#
# Usage: sh overnight.sh [bench]   (default ~/covr-bench; DRY_RUN=1 prints the steps only)
set -eu
bench=${1:-$HOME/covr-bench}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
lib=$bench/lib/4.6.2
rscript=/opt/R/4.6.2/bin/Rscript
run() {
  echo "+ $*"
  [ -n "${DRY_RUN:-}" ] || "$@"
}
tarballs() {
  for p in "$@"; do ls "$bench"/src/"${p}"_*.tar.gz; done
}

final=$here/../results/final
mkdir -p "$final"
# Coverage objects from run 1 of each package and version, for benchmarking
# post-processing later (kept out of the repository; they can be large).
export COVR_BENCH_COV_DIR="$bench/cov"

# 1. The covr main to benchmark: the commit recorded by the first start, or
# origin/main now.
if [ -f "$final/covr-sha" ]; then
  sha=$(cat "$final/covr-sha")
else
  run git -C "$repo" fetch -q origin
  sha=$(git -C "$repo" rev-parse --short origin/main)
  [ -n "${DRY_RUN:-}" ] || echo "$sha" >"$final/covr-sha"
fi
echo "covr main: $sha"
[ -d "$lib/covr-$sha/covr" ] || run sh "$repo/performance-audit/setup-commits.sh" "$bench" 4.6.2 "$sha"

# 2. Both versions on every package, interleaved, on a quiet machine.
# Packages whose tests can't share one process, or that use tinytest, run with
# type = "tests" in release-tests.
pkgs="forcats purrr checkmate roxygen2 tidyr testthat devtools dplyr cli lintr targets recipes data.table ggplot2 Luminescence mlr3 insight posterior igraph sf quanteda distributional collapse ggdist"
# languageserver: covr 3.6.5 needs over an hour and then runs out of memory
# merging (#744), so it gets one 3.6.5 run (recorded as failing) and three
# 4.0.0 runs.
tests_mode="future digest"
run env VERSIONS="3.6.5 $sha" OUT_DIR="$final/release" sh "$here/run-release.sh" "$bench" 3 $(tarballs $pkgs)
run env COVR_BENCH_TYPE=tests OUT_DIR="$final/release-tests" VERSIONS="3.6.5 $sha" \
  sh "$here/run-release.sh" "$bench" 3 $(tarballs $tests_mode)
run env VERSIONS="$sha" OUT_DIR="$final/release" sh "$here/run-release.sh" "$bench" 3 $(tarballs languageserver)
run env VERSIONS="3.6.5" RUN_TIMEOUT=7200 MEMCAP=10G OUT_DIR="$final/release" sh "$here/run-release.sh" "$bench" 1 $(tarballs languageserver)

# 3. Overhead per counted expression.
run mkdir -p "$final/counter"
for v in 3.6.5 "$sha"; do
  [ -f "$final/counter/$v.rds" ] && continue
  run env R_LIBS="$lib/covr-$v:$lib/deps" memcap 4G "$rscript" --no-init-file \
    "$here/counter-cost.R" "$v" "$final/counter/$v.rds"
done

# 4. Summarise and plot.
run sh -c "\"$rscript\" --no-init-file \"$here/summarise-release.R\" \"$sha\" \
  \"$final/release\" \"$final/release-tests\" > \"$final/summary.md\""
for plot in runs relative log; do
  script=$here/plot-release-$plot.R
  [ "$plot" = log ] && script=$here/plot-release.R
  run env R_LIBS="$lib/deps" "$rscript" --no-init-file "$script" "$sha" \
    "$final/benchmarks-$plot.png" "$final/release" "$final/release-tests"
done
echo "done: $(date)"
