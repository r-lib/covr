#!/bin/sh
# Build everything overnight.sh needs under <bench> (default ~/covr-bench,
# which survives reboots, unlike /tmp): the R 4.6.2 dependency library, the
# tarballs of the benchmark packages and covr 3.6.5. covr main is installed by
# overnight.sh itself. Safe to rerun; existing tarballs and packages are kept.
#
# Usage: sh setup-release.sh [bench]
set -eu
bench=${1:-$HOME/covr-bench}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
mkdir -p "$bench"
rscript=/opt/R/4.6.2/bin/Rscript

# covr 3.6.5, the deps of the covr versions, and forcats, checkmate and
# Luminescence (the audit's packages).
(cd "$repo" && memcap 6G "$rscript" --no-init-file performance-audit/setup.R "$bench" "$repo") \
  >"$bench/setup.log" 2>&1
grep -hE '^covr |Not installed' "$bench/setup.log" || true

# The other benchmark packages, with their Suggests.
COVR_BENCH=$bench memcap 6G "$rscript" --no-init-file "$here/deps-extra.R" \
  dplyr data.table devtools lintr \
  purrr tidyr cli roxygen2 testthat ggplot2 future mlr3 recipes targets \
  insight posterior igraph sf quanteda digest \
  distributional collapse ggdist \
  >"$bench/setup-extra.log" 2>&1
grep -E '^(tarballs|missing)' "$bench/setup-extra.log"
ls "$bench/src"/*.tar.gz | sed 's#.*/##' | tr '\n' ' '
echo
