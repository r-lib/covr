#!/bin/sh
# Time every benchmark package without covr (bench-plain.R), 3 runs each, into
# results/final next to the covr runs, as plain-<pkg>-<rep>. Skips runs that
# already have results, so it can be resumed; waits for a quiet machine like
# run-release.sh.
# Usage: sh run-plain.sh [bench]   (default ~/covr-bench)
set -u
bench=${1:-$HOME/covr-bench}
here=$(cd "$(dirname "$0")" && pwd)
final=$here/../results/final
deps=$bench/lib/4.6.2/deps
pkgs="forcats purrr checkmate roxygen2 tidyr testthat devtools dplyr cli lintr targets recipes data.table ggplot2 Luminescence mlr3 insight posterior igraph sf quanteda distributional collapse ggdist languageserver"
tests_mode="future digest"
quiet() {
  waited=0
  while [ "$(cut -d' ' -f1 /proc/loadavg | cut -d. -f1)" -ge 2 ] && [ "$waited" -lt 1800 ]; do
    sleep 60
    waited=$((waited + 60))
  done
}
for rep in 1 2 3; do
  for mode in default tests; do
    if [ "$mode" = tests ]; then list=$tests_mode; dir=$final/release-tests; else list=$pkgs; dir=$final/release; fi
    for pkg in $list; do
      out=$dir/plain-$pkg-$rep
      [ -f "$out.rds" ] && continue
      mem-ok 3000 || sleep 120
      quiet
      tarball=$(ls "$bench"/src/"$pkg"_*.tar.gz)
      echo "$(date +%T) plain $pkg rep $rep (load $(cut -d' ' -f1 /proc/loadavg))"
      env COVR_BENCH_TYPE=$([ "$mode" = tests ] && echo tests) R_LIBS="$deps" \
        timeout 3600 memcap 6G /usr/bin/time -f 'maxrss_kb=%M wall=%e' -o "$out.time" \
        /opt/R/4.6.2/bin/Rscript --no-init-file "$here/bench-plain.R" "$tarball" "$out.rds" \
        >"$out.log" 2>&1 || echo "  failed: plain $pkg rep $rep"
    done
  done
done
echo "done: $(date)"
