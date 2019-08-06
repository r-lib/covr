#pragma once

#define USE_RINTERNALS
#include <R.h>
#include <Rdefines.h>
#include <R_ext/Error.h>

template <typename R, int R_SXP>
SEXP simple2_(SEXP x) {
  R *px, *pout;

  SEXP out = PROTECT(allocVector(R_SXP, 1));

  px = (R *) DATAPTR(x);
  pout = (R *) DATAPTR(out);

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
