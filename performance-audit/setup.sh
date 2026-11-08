#!/bin/sh
# Set up the benchmark libraries for all three R versions (see setup.R).
# Usage: sh performance-audit/setup.sh [bench_dir]
set -e
bench=${1:-/tmp/covr-bench}
mkdir -p "$bench"
# The first run downloads the tarballs; the others reuse them.
/opt/R/4.6.2/bin/Rscript --no-init-file performance-audit/setup.R "$bench" >"$bench/setup-4.6.2.log" 2>&1
/opt/R/4.4.3/bin/Rscript --no-init-file performance-audit/setup.R "$bench" >"$bench/setup-4.4.3.log" 2>&1 &
/usr/bin/Rscript --no-init-file performance-audit/setup.R "$bench" >"$bench/setup-4.3.3.log" 2>&1 &
wait
grep -hE '^covr |Not installed' "$bench"/setup-*.log
