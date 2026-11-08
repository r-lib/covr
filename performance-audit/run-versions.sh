#!/bin/sh
# Time package_coverage() for each covr version and benchmark package on one
# R version, writing <bench>/out/versions/<R>-<covr>-<pkg>-<rep>.{rds,log,time}.
# Runs that already have an .rds are skipped, so the script can be resumed.
#
# Usage: VERSIONS="3.6.5 main" sh performance-audit/run-versions.sh \
#          <bench> <R version> <reps> <pkg tarball>...
# Optional: SKIP="4.4.3-3.5.1-Luminescence ..." skips those combinations,
# ONCE="4.4.3-3.6.4-Luminescence ..." runs those only in the first rep,
# TIMEOUT (seconds, default 3600) per run.
set -u
bench=$1
rver=$2
reps=$3
shift 3
case $rver in
4.3.3) rscript=/usr/bin/Rscript ;;
*) rscript=/opt/R/$rver/bin/Rscript ;;
esac
here=$(cd "$(dirname "$0")" && pwd)
out_dir=$bench/out/${OUT_SUBDIR:-versions}
mkdir -p "$out_dir"

for rep in $(seq "$reps"); do
  for tarball in "$@"; do
    pkg=$(basename "$tarball" | sed 's/_.*//')
    for v in $VERSIONS; do
      combo=$rver-$v-$pkg
      case " ${SKIP:-} " in *" $combo "*) continue ;; esac
      if [ "$rep" -gt 1 ]; then
        case " ${ONCE:-} " in *" $combo "*) continue ;; esac
      fi
      out=$out_dir/$combo-$rep
      [ -f "$out.rds" ] && continue
      mem-ok 3000 || sleep 120
      echo "$(date +%T) $combo rep $rep"
      report=${REPORT:-true}
      [ "$rep" -gt 1 ] && report=false
      COVR_BENCH_REPORT=$report R_LIBS=$bench/lib/$rver/covr-$v:$bench/lib/$rver/deps \
        timeout "${TIMEOUT:-3600}" memcap 6G \
        /usr/bin/time -f 'maxrss_kb=%M wall=%e' -o "$out.time" \
        "$rscript" --no-init-file "$here/bench-versions.R" "$tarball" "$v" "$out.rds" \
        >"$out.log" 2>&1 || echo "  failed: $combo rep $rep (see $out.log)"
    done
  done
done
