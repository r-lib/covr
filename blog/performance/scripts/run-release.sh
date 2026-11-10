#!/bin/sh
# Interleaved runs of bench-release.R comparing covr versions on R 4.6.2,
# writing <bench>/out/<OUT_SUBDIR, default release>/<covr>-<pkg>-<rep>.{rds,log,time}.
# report() is only timed in the first rep. Runs that already have an .rds are
# skipped, so the script can be resumed. COVR_BENCH_TYPE is passed on to
# bench-release.R.
#
# Usage: VERSIONS="3.6.5 aaa75cf" sh run-release.sh <bench> <reps> <tarball>...
set -u
bench=$1
reps=$2
shift 2
here=$(cd "$(dirname "$0")" && pwd)
lib=$bench/lib/4.6.2
# OUT_DIR, if set, is used as is (e.g. a directory in the repository, so each
# result is kept on disk the moment its run finishes).
out_dir=${OUT_DIR:-$bench/out/${OUT_SUBDIR:-release}}
mkdir -p "$out_dir"

# CPU use of the Windows host in percent (which includes the WSL2 VM), averaged
# over 3 samples; empty outside WSL. /proc/loadavg only sees the Linux VM, so
# Windows work (Defender scans, updates, browsers) would otherwise go unseen.
ps_exe=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
host_cpu() {
  [ -x "$ps_exe" ] || return 0
  "$ps_exe" -NoProfile -Command '$s = 1..3 | % { (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average; Start-Sleep 2 }; [math]::Round(($s | Measure-Object -Average).Average)' 2>/dev/null | tr -d '\r'
}
busy() {
  [ "$(cut -d' ' -f1 /proc/loadavg | cut -d. -f1)" -ge "${QUIET_LOAD:-2}" ] && return 0
  cpu=$(host_cpu)
  [ -n "$cpu" ] && [ "$cpu" -ge "${QUIET_HOST_CPU:-15}" ] && return 0
  return 1
}

for rep in $(seq "$reps"); do
  for tarball in "$@"; do
    pkg=$(basename "$tarball" | sed 's/_.*//')
    for v in $VERSIONS; do
      out=$out_dir/$v-$pkg-$rep
      [ -f "$out.rds" ] && continue
      mem-ok 3000 || sleep 120
      # Wait up to 30 minutes for a quiet machine: the WSL 1-minute load below
      # QUIET_LOAD (default 2) and the Windows host's CPU use below
      # QUIET_HOST_CPU percent (default 15). Then run anyway; both are logged.
      waited=0
      while busy && [ "$waited" -lt 1800 ]; do
        sleep 60
        waited=$((waited + 60))
      done
      load=$(cut -d' ' -f1-3 /proc/loadavg)
      cpu=$(host_cpu)
      echo "$(date +%T) $v $pkg rep $rep (load $load, host cpu ${cpu:-?}%, waited ${waited}s)"
      echo "load=$load host_cpu=${cpu:-NA} waited=$waited" >"$out.load"
      report=true
      [ "$rep" -gt 1 ] && report=false
      COVR_BENCH_REPORT=$report R_LIBS=$lib/covr-$v:$lib/deps \
        timeout 3600 memcap 6G \
        /usr/bin/time -f 'maxrss_kb=%M wall=%e' -o "$out.time" \
        /opt/R/4.6.2/bin/Rscript --no-init-file "$here/bench-release.R" "$tarball" "$v" "$out.rds" \
        >"$out.log" 2>&1 || echo "  failed: $v $pkg rep $rep (see $out.log)"
    done
  done
done
