#!/bin/sh
# Time covr measuring its own coverage (as in the test-coverage workflow) at
# the given commits: the installed covr is the commit's version and the source
# is the commit's, renamed to covrShim by its shim_package.sh. Each commit runs
# its own test suite, so compare a commit with its parent rather than across
# distant commits. Writes <bench>/out/self/<R>-<sha>-<rep>.{log,time}.
#
# Usage: sh performance-audit/bench-self.sh <bench> <R version> <reps> <commit>...
# The commits must have been installed with setup-commits.sh.
set -u
bench=$1
rver=$2
reps=$3
shift 3
case $rver in
4.3.3) rscript=/usr/bin/Rscript ;;
*) rscript=/opt/R/$rver/bin/Rscript ;;
esac
out_dir=$bench/out/self
mkdir -p "$out_dir"
for rep in $(seq "$reps"); do
  for commit in "$@"; do
    sha=$(git rev-parse --short "$commit")
    out=$out_dir/$rver-$sha-$rep
    [ -f "$out.time" ] && grep -q '^ok' "$out.time" && continue
    mem-ok 3000 || sleep 120
    echo "$(date +%T) $commit ($sha) rep $rep"
    dir=$(mktemp -d)
    cp -r "$bench/src/covr-$sha/." "$dir"
    (cd "$dir" && sh shim_package.sh >/dev/null 2>&1)
    start=$(date +%s.%N)
    (cd "$dir" && R_LIBS=$bench/lib/$rver/covr-$sha:$bench/lib/$rver/deps \
      timeout 3600 memcap 6G /usr/bin/time -f 'maxrss_kb=%M wall=%e' -o "$out.rss" \
      "$rscript" --no-init-file -e \
      'cov <- covr::package_coverage(quiet = TRUE); print(cov); cat("percent:", covr::percent_coverage(cov), "\n")' \
      >"$out.log" 2>&1)
    status=$?
    end=$(date +%s.%N)
    if [ $status -eq 0 ]; then
      printf 'ok %s %s\n' "$(echo "$end - $start" | bc)" "$(cat "$out.rss")" >"$out.time"
    else
      echo "  failed: $commit rep $rep (see $out.log)"
      printf 'failed %s\n' "$(echo "$end - $start" | bc)" >"$out.time"
    fi
    rm -rf "$dir"
  done
done
