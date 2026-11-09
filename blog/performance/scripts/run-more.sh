#!/bin/sh
# Interleaved runs of bench-tests.R: baseline (#734), install-time with and
# without compiling. Usage: sh run-more.sh <reps> <tarball>...
B=/tmp/covr-bench; L=$B/lib/4.6.2; out=$B/out/more; mkdir -p $out
reps=$1; shift
for rep in $(seq $reps); do for t in "$@"; do
  pkg=$(basename $t | sed 's/_.*//')
  for v in base it itnc; do
    f=$out/$pkg-$v-$rep
    [ -f $f.rds ] && continue
    case $v in
      base) lib=/tmp/cc-lib6; env= ;;
      it) lib=$L/covr-installtime; env= ;;
      itnc) lib=$L/covr-installtime; env=COVR_INSTALL_COMPILE=false ;;
    esac
    mem-ok 3000 || sleep 120
    env $env R_LIBS=$lib:$L/deps timeout 3600 memcap 6G \
      /usr/bin/time -f 'maxrss_kb=%M wall=%e' -o $f.time \
      /opt/R/4.6.2/bin/Rscript --no-init-file $B/bench-tests.R $t $v $f.rds > $f.log 2>&1
    tail -1 $f.log
  done
done; done
