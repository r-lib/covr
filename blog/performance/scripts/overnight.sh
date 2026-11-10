#!/bin/sh
# The final covr 3.6.5 vs 4.0.0 benchmarks for the release blog post, run
# sequentially overnight. Requires r-lib/covr#741 to be merged: covr main is
# installed and timed against the 3.6.5 runs already in <bench>/out/release.
#
# Usage: sh overnight.sh <bench>        (DRY_RUN=1 prints the steps only)
set -eu
bench=$1
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

# 1. #741 must be merged; install covr main.
state=$(gh pr view 741 -R r-lib/covr --json state -q .state)
if [ "$state" != "MERGED" ] && [ -z "${DRY_RUN:-}" ]; then
  echo "r-lib/covr#741 is $state, not merged; stopping" >&2
  exit 1
fi
run git -C "$repo" fetch -q origin
sha=$(git -C "$repo" rev-parse --short origin/main)
echo "covr main: $sha"
run sh "$repo/performance-audit/setup-commits.sh" "$bench" 4.6.2 "$sha"

# 2. Set aside every earlier run: they were made while the machine was busy
# with other work (and future's sourced all its test scripts in one process,
# which its tests don't support). Kept for the record, not summarised.
busy=$bench/out/busy-$(date +%Y%m%d)
run mkdir -p "$busy"
for d in release release-tests; do
  [ -d "$bench/out/$d" ] && run mv "$bench/out/$d" "$busy/$d"
done

# 3. Both versions on every package, interleaved, on a quiet machine.
# Packages whose tests can't share one process, or that use tinytest, run with
# type = "tests" in out/release-tests.
pkgs="forcats purrr checkmate roxygen2 tidyr testthat devtools dplyr cli lintr targets recipes data.table ggplot2 Luminescence mlr3 insight posterior igraph sf quanteda distributional languageserver collapse ggdist"
tests_mode="future digest"
run env VERSIONS="3.6.5 $sha" sh "$here/run-release.sh" "$bench" 3 $(tarballs $pkgs)
run env COVR_BENCH_TYPE=tests OUT_SUBDIR=release-tests VERSIONS="3.6.5 $sha" \
  sh "$here/run-release.sh" "$bench" 3 $(tarballs $tests_mode)

# 4. Overhead per counted expression.
run mkdir -p "$bench/out/counter"
for v in 3.6.5 "$sha"; do
  run env R_LIBS="$lib/covr-$v:$lib/deps" memcap 4G "$rscript" --no-init-file \
    "$here/counter-cost.R" "$v" "$bench/out/counter/$v.rds"
done

# 5. Keep the results in results/final (the earlier, busy-machine runs stay in
# results/release and results/release-tests) and summarise and plot them.
final=$here/../results/final
for d in release release-tests counter; do
  run mkdir -p "$final/$d"
  run cp -r "$bench/out/$d/." "$final/$d/"
done
run sh -c "\"$rscript\" --no-init-file \"$here/summarise-release.R\" \"$sha\" \
  \"$final/release\" \"$final/release-tests\" > \"$final/summary.md\""
for plot in runs relative log; do
  script=$here/plot-release-$plot.R
  [ "$plot" = log ] && script=$here/plot-release.R
  run env R_LIBS="$lib/deps" "$rscript" --no-init-file "$script" "$sha" \
    "$final/benchmarks-$plot.png" "$final/release" "$final/release-tests"
done
echo "done: $(date)"
