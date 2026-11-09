#!/bin/sh
# covr measuring its own coverage (shim_package.sh) for base / it / itnc.
B=/tmp/covr-bench; L=$B/lib/4.6.2; out=$B/out/more-self; mkdir -p $out
for rep in 1 2; do for v in base it itnc; do
  f=$out/$v-$rep
  [ -f $f.txt ] && continue
  case $v in base) s=base; env= ;; it) s=it; env= ;; itnc) s=it; env=COVR_INSTALL_COMPILE=false ;; esac
  d=$(mktemp -d); cp -r $B/src/covr-self-$s/. $d; (cd $d && sh shim_package.sh >/dev/null 2>&1)
  mem-ok 3000 || sleep 120
  start=$(date +%s.%N)
  (cd $d && env $env NOT_CRAN=true R_LIBS=$L/covr-self-$s:$L/deps timeout 3600 memcap 6G \
    /opt/R/4.6.2/bin/Rscript --no-init-file -e 'cov <- covr::package_coverage(quiet = TRUE); cat("percent:", covr::percent_coverage(cov), "\n")' > $f.log 2>&1)
  st=$?; end=$(date +%s.%N)
  echo "$v rep $rep status $st $(echo "$end - $start" | bc) s $(grep percent $f.log)" | tee $f.txt
  rm -rf $d
done; done
