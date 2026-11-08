#include <R.h>
#include <Rinternals.h>
#include "TestRcppInterfaces_RcppExports.h"
#include "helper.h"

extern "C" SEXP simple_(SEXP x) {
  return Rf_ScalarInteger(sign(Rf_asInteger(x)));
}
