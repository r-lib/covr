#include <R.h>
#include <Rinternals.h>
#include <stdint.h>
#include <stdlib.h>

/* The counts of the traces are held here, in the order their keys were added,
 * and instrumented code passes the key of its trace to `covr_count()`. R keeps
 * a single `CHARSXP` for each string, so keys are looked up by the address of
 * their `CHARSXP` in a hash table. The code can be serialized, e.g. in the
 * lazy-load database of an instrumented package or sent to another process.
 * Keys that are not added to the process, e.g. because a function was sent to
 * another process, are ignored. A key keeps its count for the life of the
 * process, also after `clear_counters()`. */
static double *counts = NULL;
static SEXP keys = NULL; // a preserved STRSXP, for reading the counts back
static int n_keys = 0;
static int capacity = 0;

// An open addressing table of the keys' `CHARSXP` addresses to their index + 1.
static SEXP *table_keys = NULL;
static int *table_index = NULL;
static size_t table_size = 0; // a power of two, at least twice n_keys

static size_t slot_of(SEXP x, size_t mask) {
  uint64_t h = ((uint64_t)(uintptr_t)x >> 4) * 0x9E3779B97F4A7C15ull;
  return (size_t)(h >> 20) & mask;
}

// The index of the key `x`, or -1.
static int find(SEXP x) {
  if (table_size == 0) {
    return -1;
  }
  size_t mask = table_size - 1;
  for (size_t i = slot_of(x, mask);; i = (i + 1) & mask) {
    if (table_keys[i] == x) {
      return table_index[i] - 1;
    }
    if (table_keys[i] == NULL) {
      return -1;
    }
  }
}

static void insert(SEXP x, int index) {
  size_t mask = table_size - 1;
  size_t i = slot_of(x, mask);
  while (table_keys[i] != NULL) {
    i = (i + 1) & mask;
  }
  table_keys[i] = x;
  table_index[i] = index + 1;
}

static void grow(void) {
  int new_capacity = capacity == 0 ? 4096 : capacity * 2;
  double *new_counts =
      (double *)realloc(counts, (size_t)new_capacity * sizeof(double));
  if (new_counts == NULL) {
    Rf_error("can't allocate memory for the counts");
  }
  counts = new_counts;
  size_t new_size = (size_t)new_capacity * 2;
  SEXP *new_table_keys = (SEXP *)calloc(new_size, sizeof(SEXP));
  int *new_table_index = (int *)calloc(new_size, sizeof(int));
  if (new_table_keys == NULL || new_table_index == NULL) {
    free(new_table_keys);
    free(new_table_index);
    Rf_error("can't allocate memory for the counts");
  }
  SEXP new_keys = PROTECT(Rf_allocVector(STRSXP, new_capacity));
  for (int i = 0; i < n_keys; ++i) {
    SET_STRING_ELT(new_keys, i, STRING_ELT(keys, i));
  }
  R_PreserveObject(new_keys);
  if (keys != NULL) {
    R_ReleaseObject(keys);
  }
  keys = new_keys;
  UNPROTECT(1);

  free(table_keys);
  free(table_index);
  table_keys = new_table_keys;
  table_index = new_table_index;
  table_size = new_size;
  capacity = new_capacity;
  for (int i = 0; i < n_keys; ++i) {
    insert(STRING_ELT(keys, i), i);
  }
}

// `Rf_charIsASCII()` is only in R's API since R 4.5.0.
static int is_ascii(SEXP x) {
  for (const unsigned char *s = (const unsigned char *)CHAR(x); *s; ++s) {
    if (*s > 127) {
      return 0;
    }
  }
  return 1;
}

static SEXP utf8_key(SEXP x) {
  return Rf_mkCharCE(Rf_translateCharUTF8(x), CE_UTF8);
}

static void add_key(SEXP x) {
  if (find(x) >= 0) {
    return;
  }
  // Strings of the other encoding are found by their UTF-8 form, see
  // `covr_count()`.
  if (!is_ascii(x) && Rf_getCharCE(x) != CE_UTF8) {
    x = utf8_key(x);
    if (find(x) >= 0) {
      return;
    }
  }
  if (n_keys == capacity) {
    PROTECT(x);
    grow();
    UNPROTECT(1);
  }
  SET_STRING_ELT(keys, n_keys, x);
  counts[n_keys] = 0;
  insert(x, n_keys);
  ++n_keys;
}

// Add a count for each of the strings `keys` that has none yet.
SEXP covr_counter_add(SEXP keys_) {
  R_xlen_t n = XLENGTH(keys_);
  for (R_xlen_t i = 0; i < n; ++i) {
    add_key(STRING_ELT(keys_, i));
  }
  return R_NilValue;
}

// Called by instrumented code for every evaluated expression.
SEXP covr_count(SEXP key) {
  SEXP x = STRING_ELT(key, 0);
  int i = find(x);
  if (i >= 0) {
    counts[i]++;
  } else if (!is_ascii(x)) {
    // The same string with another encoding is another `CHARSXP`.
    SEXP u = PROTECT(utf8_key(x));
    i = find(u);
    if (i >= 0) {
      counts[i]++;
    }
    UNPROTECT(1);
  }
  return R_NilValue;
}

// A named numeric vector of the non-zero counts (named by key), which are reset.
SEXP covr_counter_take(void) {
  int n = 0;
  for (int i = 0; i < n_keys; ++i) {
    if (counts[i] != 0) {
      ++n;
    }
  }
  SEXP res = PROTECT(Rf_allocVector(REALSXP, n));
  SEXP nms = PROTECT(Rf_allocVector(STRSXP, n));
  for (int i = 0, j = 0; i < n_keys; ++i) {
    if (counts[i] != 0) {
      REAL(res)[j] = counts[i];
      SET_STRING_ELT(nms, j, STRING_ELT(keys, i));
      counts[i] = 0;
      ++j;
    }
  }
  Rf_setAttrib(res, R_NamesSymbol, nms);
  UNPROTECT(2);
  return res;
}

// Discard the counts, keeping the keys.
SEXP covr_counter_reset(void) {
  for (int i = 0; i < n_keys; ++i) {
    counts[i] = 0;
  }
  return R_NilValue;
}
