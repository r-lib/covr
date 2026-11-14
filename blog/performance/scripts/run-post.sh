#!/bin/sh
# Time covr's post-processing functions (bench-post.R) on the coverage objects
# saved by the overnight benchmark, for each package with objects from both
# covr 3.6.5 and covr main: covr 3.6.5 on its own objects, and covr <sha> on
# those of <cov_sha> (the main commit the benchmark ran). Resumable.
#
# Usage: sh run-post.sh <sha> [cov_sha] [bench] [iterations]
set -eu
sha=$1
cov_sha=${2:-217c09eb}
bench=${3:-$HOME/covr-bench}
iterations=${4:-5}
here=$(cd "$(dirname "$0")" && pwd)
out=$here/../results/tests/post
lib=$bench/lib/4.6.2
rscript=/opt/R/4.6.2/bin/Rscript
mkdir -p "$out"
echo "$sha" >"$out/covr-sha"

for f in "$bench"/cov/3.6.5-*.rds; do
  pkg=$(basename "$f" .rds)
  pkg=${pkg#3.6.5-}
  [ -f "$bench/cov/$cov_sha-$pkg.rds" ] || continue
  for v in 3.6.5 "$sha"; do
    res=$out/$v-$pkg.rds
    [ -f "$res" ] && continue
    case $v in
    3.6.5) cov=$f ;;
    *) cov=$bench/cov/$cov_sha-$pkg.rds ;;
    esac
    echo "== $pkg $v"
    R_LIBS=$lib/covr-$v:$lib/deps memcap 4G "$rscript" --no-init-file \
      "$here/bench-post.R" "$cov" "$v" "$res" "$iterations" ||
      echo "FAILED: $pkg $v"
  done
done
