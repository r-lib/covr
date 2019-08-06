#define USE_RINTERNALS
#include <R.h>
#include <Rdefines.h>
#include <R_ext/Error.h>
#include "simple-header.h"

extern "C" SEXP simple_(SEXP x) {
  double *px, *pout;

  SEXP out = PROTECT(allocVector(REALSXP, 1));

  px = REAL(x);
  pout = REAL(out);

  if (px[0] >= 1) {
    pout[0] = 1;
  }
  else if (px[0] == 0) {
    pout[0] = 0;
  } else {
    pout[0] = -1;
  }
  UNPROTECT(1);

  return out;
}

extern "C" SEXP simple3_(SEXP x) {
  return simple2_<double, REALSXP>(x);
}
