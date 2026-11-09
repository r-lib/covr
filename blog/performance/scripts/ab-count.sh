#!/bin/sh
# Interleaved A/B of the instrumented Luminescence test run: covr main vs merged branch.
B=/tmp/covr-bench; L=$B/lib/4.6.2
rm -rf /tmp/ab-main /tmp/ab-int; mkdir -p /tmp/ab-main /tmp/ab-int
for v in main int; do
  R_LIBS=$L/covr-$v:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file -e "
    src <- tempfile(); dir.create(src); untar('$B/src/Luminescence_0.9.25.tar.gz', exdir = src)
    pkg <- covr:::as_package(file.path(src, 'Luminescence'))
    covr:::install_package(pkg, '/tmp/ab-$v', getOption('covr.flags'), quiet = TRUE)
    covr:::add_hooks('Luminescence', '/tmp/ab-$v')" >/dev/null 2>&1 &
done
wait
for rep in 1 2 3; do for v in main int; do
  d=$(mktemp -d); s=$(mktemp -d)
  R_LIBS=/tmp/ab-$v:$L/covr-$v:$L/deps TRACE_SAVE_DIR=$d COVERAGE_DIR=$s R_COVR=true \
    /opt/R/4.6.2/bin/Rscript --vanilla performance-audit/phase-child.R instr Luminescence /tmp/ab-$v-$rep.rds >/dev/null 2>&1
  /opt/R/4.6.2/bin/Rscript --vanilla -e "x <- readRDS('/tmp/ab-$v-$rep.rds'); cat('$v rep $rep covr', x\$covr, 'load', x\$load, 'tests', x\$tests, 'counts', x\$n_counts, '\n')"
done; done
