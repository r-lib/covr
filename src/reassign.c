#define USE_RINTERNALS
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Error.h>
#include <R_ext/Rdynload.h>
#include <Rdefines.h>
#include <stdlib.h>  // for NULL
#include <stdint.h> // for uint64_t


inline static
void CheckBody(SEXP x) {
  switch (TYPEOF(x)) {
  case NILSXP:
  case SYMSXP:
  case LISTSXP:
  // case CLOSXP:
  case ENVSXP:
  case PROMSXP:
  case LANGSXP:
  // case SPECIALSXP:
  // case BUILTINSXP:
  case CHARSXP:
  case LGLSXP:
  case INTSXP:
  case REALSXP:
  case CPLXSXP:
  case STRSXP:
  // case DOTSXP:
  // case ANYSXP:
  case VECSXP:
  case EXPRSXP:
  case BCODESXP:
  case EXTPTRSXP:
  case WEAKREFSXP:
  case RAWSXP:
  case S4SXP: // renamed to OBJSXP
    return;

  default:
    error("Unexpected closure body type");
  }
}

inline static
void CheckEnvironment(SEXP x) {
  if(TYPEOF(x) != ENVSXP)
    error("Unexpected closure env type");
}

inline static
void CheckFormals(SEXP ls) {
  // copied from R:
  // https://github.com/wch/r-source/blob/tags/R-4-4-2/src/main/eval.c#L3842-L3852
  if (isList(ls)) {
    for (; ls != R_NilValue; ls = CDR(ls))
      if (TYPEOF(TAG(ls)) != SYMSXP)
        goto err;
    return;
  }
  err:
    error("Unexpected closure formals");
}

SEXP covr_reassign_function(SEXP old_fun, SEXP new_fun) {
  if (TYPEOF(old_fun) != CLOSXP) error("old_fun must be a function");
  if (TYPEOF(new_fun) != CLOSXP) error("new_fun must be a function");

  // The goal is to modify `old_fun` in place, so that all existing references
  // to `old_fun` call the tracing `new_fun` instead.
  // This used to be simply:
  //   SET_FORMALS(old_fun, FORMALS(new_fun));
  //   SET_BODY(old_fun, BODY(new_fun));
  //   SET_CLOENV(old_fun, CLOENV(new_fun));
  // But those functions are now "non-API". So we comply with the letter of the
  // law and swap the fields manually, making some hard assumptions about the
  // underlying memory layout in the process.
  // Rather than using memcpy() with a hard-coded byte offset, we mirror the R
  // internals SEXPREC struct defs here, to hopefully match the alignment
  // behavior of R (e.g., on windows).

  // Mirror the exact structures of SEXPREC from R internals
  struct proxy_sxpinfo_struct {
    uint64_t bits;  // guaranteed to be 64 bits
  };

  struct proxy_closxp_struct {
    struct SEXPREC *formals;
    struct SEXPREC *body;
    struct SEXPREC *env;
  };

  struct proxy_sexprec {
    struct proxy_sxpinfo_struct sxpinfo;
    struct SEXPREC *attrib;
    struct SEXPREC *gengc_next_node, *gengc_prev_node;
    union {
      struct proxy_closxp_struct closxp;
      // We could add other union members if needed
    } u;
  };

  typedef struct proxy_sexprec* proxy_sexp;

  proxy_sexp old = (proxy_sexp) old_fun;
  proxy_sexp new = (proxy_sexp) new_fun;

  // Sanity checks. If the closxp struct is not what we expect, then the
  // underlying internal memory layout of a CLOSXP has probably changed and we
  // need to update this code.
  // https://github.com/wch/r-source/blob/tags/R-4-4-2/src/include/Defn.h#L170-L174
  CheckFormals(old->u.closxp.formals);
  CheckFormals(new->u.closxp.formals);
  CheckBody(old->u.closxp.body);
  CheckBody(new->u.closxp.body);
  CheckEnvironment(old->u.closxp.env);
  CheckEnvironment(new->u.closxp.env);

  MARK_NOT_MUTABLE(old_fun);
  MARK_NOT_MUTABLE(old->u.closxp.body);
  MARK_NOT_MUTABLE(old->u.closxp.env);
  MARK_NOT_MUTABLE(old->u.closxp.formals);

  MARK_NOT_MUTABLE(new_fun);
  MARK_NOT_MUTABLE(new->u.closxp.body);
  MARK_NOT_MUTABLE(new->u.closxp.env);
  MARK_NOT_MUTABLE(new->u.closxp.formals);

  old->u.closxp = new->u.closxp;

  // Duplicate attributes is still not "non-API", thankfully.
  DUPLICATE_ATTRIB(old_fun, new_fun);

  return R_NilValue;
}


SEXP covr_duplicate_(SEXP x) { return duplicate(x); }

/* .Call calls */
extern SEXP covr_duplicate_(SEXP);
extern SEXP covr_reassign_function(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"covr_duplicate_", (DL_FUNC)&covr_duplicate_, 1},
    {"covr_reassign_function", (DL_FUNC)&covr_reassign_function, 2},
    {NULL, NULL, 0}};

void R_init_covr(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
