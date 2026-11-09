#!/bin/sh
# Install covr at the given commits of this repository into
# <bench>/lib/<R>/covr-<sha>, and keep their sources in <bench>/src/covr-<sha>
# (used by bench-self.sh). Requires setup.R to have created the deps library.
#
# Usage: sh performance-audit/setup-commits.sh <bench> <R version> <commit>...
set -eu
bench=$1
rver=$2
shift 2
case $rver in
4.3.3) r=/usr/bin/R ;;
*) r=/opt/R/$rver/bin/R ;;
esac
for commit in "$@"; do
  sha=$(git rev-parse --short "$commit")
  src=$bench/src/covr-$sha
  lib=$bench/lib/$rver/covr-$sha
  if [ ! -d "$src" ]; then
    mkdir -p "$src"
    git archive "$sha" | tar -x -C "$src"
  fi
  if [ ! -d "$lib/covr" ]; then
    mkdir -p "$lib"
    R_LIBS=$bench/lib/$rver/deps "$r" CMD INSTALL --no-test-load -l "$lib" "$src" >/dev/null 2>&1 &&
      echo "$commit ($sha): ok" || echo "$commit ($sha): FAILED"
  fi
done
