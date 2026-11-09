#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param parent_functions the functions which this call is a child of.
#' @param parent_ref argument used to set the srcref of the current call during
#'   the recursion.
#' @param impute_ref a function returning the srcref of the current call, if it
#'   has no srcref of its own. It is only called to impute srcrefs for nested
#'   conditionals, so the expressions in their branches get their own counters.
#' @seealso <http://adv-r.had.co.nz/Expressions.html>
#' @return a modified expression with count calls inserted before each previous
#' call.
#' @keywords internal
trace_calls <- function(
  x,
  parent_functions = NULL,
  parent_ref = NULL,
  impute_ref = NULL
) {
  # Construct the calls by hand to avoid a NOTE from R CMD check
  record_tests <- isTRUE(getOption("covr.record_tests", FALSE))
  count <- function(key, val) {
    count_call <- if (record_tests) {
      as.call(list(
        call(":::", as.symbol("covr"), as.symbol("count_and_record")),
        key
      ))
    } else {
      # The `.Call` primitive itself rather than the symbol, so a `.Call`
      # defined where the traced function lives can't mask it. Primitives are
      # serialized by name, and keys are strings, so traced functions can be
      # saved, e.g. in the lazy-load database of an instrumented package. In
      # a process where the key isn't registered, e.g. one that a traced
      # function was sent to, the call runs but doesn't count.
      as.call(list(
        .Call,
        call(":::", as.symbol("covr"), as.symbol("covr_count")),
        key
      ))
    }
    call("if", TRUE, call("{", count_call, val))
  }

  if (is.null(parent_functions)) {
    parent_functions <- deparse(substitute(x))
  }
  recurse <- function(y) {
    lapply(y, trace_calls, parent_functions = parent_functions)
  }
  # `ref` is a function returning the srcref of `y`. The srcrefs of the
  # components of `y` are only looked up in the parse data when a conditional
  # nested in them needs one, and then only once for all of them.
  recurse_imputed <- function(y, ref) {
    if (is.null(ref)) {
      return(recurse(y))
    }
    refs <- NULL
    child_ref <- function(i) {
      force(i)
      function() {
        if (is.null(refs)) {
          refs <<- impute_child_srcrefs(y, ref()) %||% list()
        }
        if (i <= length(refs)) refs[[i]]
      }
    }
    Map(
      function(z, i) {
        trace_calls(
          z,
          parent_functions = parent_functions,
          impute_ref = child_ref(i)
        )
      },
      y,
      seq_along(y)
    )
  }

  if (is.atomic(x) || is.name(x) || is.null(x)) {
    if (is.null(parent_ref)) {
      x
    } else {
      if (is_na(x) || is_brace(x)) {
        x
      } else {
        key <- new_counter(parent_ref, parent_functions) # nolint
        count(key, x)
      }
    }
  } else if (is.call(x)) {
    # `impute_srcref()` only needs the srcref of conditionals, so `impute_ref()`
    # is not called for other calls.
    src_ref <- attr(x, "srcref")
    own_ref <- NULL
    if (is.null(src_ref) && is_conditional_or_loop(x)) {
      own_ref <- parent_ref %||% (if (!is.null(impute_ref)) impute_ref())
      src_ref <- impute_srcref(x, own_ref)
    }
    if (
      (identical(x[[1]], as.name("<-")) || identical(x[[1]], as.name("="))) && # nolint
        (is.call(x[[3]]) && identical(x[[3]][[1]], as.name("function")))
    ) {
      parent_functions <- c(parent_functions, as.character(x[[2]]))
    }

    # do not try to trace curly curly
    if (
      identical(x[[1]], as.name("{")) &&
        length(x) == 2 &&
        is.call(x[[2]]) &&
        identical(x[[2]][[1]], as.name("{"))
    ) {
      as.call(x)
    } else if (!is.null(src_ref)) {
      res <- as.call(Map(
        trace_calls,
        x,
        src_ref,
        MoreArgs = list(parent_functions = parent_functions)
      ))
      # Branch coverage is opt-in, and only changes the instrumentation when
      # it is enabled (#279).
      if (!is.null(own_ref) && isTRUE(getOption("covr.branch_coverage"))) {
        res <- trace_branches(res, x, own_ref, parent_functions)
      }
      res
    } else if (!is.null(parent_ref)) {
      key <- new_counter(parent_ref, parent_functions)
      count(key, as.call(recurse_imputed(x, function() parent_ref)))
    } else {
      as.call(recurse_imputed(x, impute_ref))
    }
  } else if (is.function(x)) {
    # We cannot trace primitive functions
    if (is.primitive(x)) {
      return(x)
    }

    fun_body <- body(x)

    if (
      !is.null(attr(x, "srcref")) &&
        (is.symbol(fun_body) || !identical(fun_body[[1]], as.name("{")))
    ) {
      src_ref <- attr(x, "srcref")
      key <- new_counter(src_ref, parent_functions)
      fun_body <- count(
        key,
        trace_calls(
          fun_body,
          parent_functions,
          impute_ref = function() impute_body_srcref(src_ref)
        )
      )
    } else {
      fun_body <- trace_calls(fun_body, parent_functions)
    }

    new_formals <- trace_formals(
      formals(x),
      parent_functions,
      attr(x, "srcref")
    )
    if (is.null(new_formals)) {
      new_formals <- list()
    }
    formals(x) <- new_formals
    body(x) <- fun_body
    x
  } else if (is.pairlist(x)) {
    as.pairlist(recurse(x))
  } else if (is.expression(x)) {
    as.expression(recurse(x))
  } else if (is.list(x)) {
    recurse(x)
  } else {
    message("Unknown language class: ", paste(class(x), collapse = "/"))
    x
  }
}

.counters <- new.env(parent = emptyenv())
.current_test <- new.env(parent = emptyenv())

# Make `covr_count()` count the evaluations of `key` (see src/count.c). A key
# keeps its count for the life of the process, also after `clear_counters()`,
# so instrumented functions always count into their own trace.
register_count <- function(key) {
  invisible(.Call(covr_counter_add, key))
}

# Add the counts held in C to the values of the traces and reset them. Call
# before reading the values of `.counters`.
sync_counts <- function() {
  counts <- .Call(covr_counter_take)
  for (key in names(counts)) {
    if (!is.null(.counters[[key]]$value)) {
      .counters[[key]]$value <- .counters[[key]]$value + counts[[key]]
    }
  }
  invisible()
}


#' initialize a new counter
#'
#' @param src_ref a [base::srcref()]
#' @param parent_functions the functions that this srcref is contained in.
#' @keywords internal
new_counter <- function(src_ref, parent_functions) {
  key <- key(src_ref)
  # Keep the counts of a trace that already exists, e.g. when a function is
  # replaced in an environment that is traced again (#641).
  if (is.null(.counters[[key]]$value)) {
    .counters[[key]]$value <- 0
  }
  if (!isTRUE(getOption("covr.record_tests", FALSE))) {
    register_count(key)
  }
  .counters[[key]]$srcref <- src_ref
  .counters[[key]]$functions <- parent_functions
  if (
    isTRUE(getOption("covr.record_tests", FALSE)) &&
      is.null(.counters[[key]]$tests)
  ) {
    new_test_counter(key)
  }
  key
}

#' increment a given counter
#'
#' @param key generated with [key()]
#' @keywords internal
count <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1L
}

#' increment a given counter and record the test that hit it
#'
#' Used instead of [count()] in code instrumented with
#' `options(covr.record_tests = TRUE)`.
#'
#' @param key generated with [key()]
#' @keywords internal
count_and_record <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1L
  count_test(key)
}

# Whether the body of `fun` was already instrumented by `trace_calls()`.
is_traced <- function(fun) {
  if (!is.function(fun) || is.primitive(fun)) {
    return(FALSE)
  }
  x <- body(fun)
  # Instrumented bodies start with a counter, so check that before searching
  # the whole body.
  if (starts_with_count(x)) {
    return(TRUE)
  }
  # `all.names()` is fast, so only search functions that might be traced.
  nms <- all.names(x)
  any(c("count", "count_and_record", "covr_count") %in% nms) &&
    "covr" %in% nms &&
    has_count_call(x)
}

# Whether `x` is `if (TRUE) { <count call>; expr }`, as added by
# `trace_calls()`, or a `{` call that starts with it.
starts_with_count <- function(x) {
  if (!is.call(x)) {
    return(FALSE)
  }
  if (identical(x[[1L]], as.name("{")) && length(x) > 1L) {
    x <- x[[2L]]
  }
  is.call(x) &&
    length(x) == 3L &&
    identical(x[[1L]], as.name("if")) &&
    isTRUE(x[[2L]]) &&
    is.call(x[[3L]]) &&
    length(x[[3L]]) > 1L &&
    is.call(x[[3L]][[2L]]) &&
    is_covr_count_call(x[[3L]][[2L]])
}

# Stops at the first counter, which instrumented code has near its start.
has_count_call <- function(x) {
  if (!is.call(x)) {
    return(FALSE)
  }
  if (is_covr_count_call(x)) {
    return(TRUE)
  }
  for (i in seq_along(x)) {
    if (is.call(x[[i]]) && has_count_call(x[[i]])) {
      return(TRUE)
    }
  }
  FALSE
}

#' clear all previous counters
#'
#' @keywords internal
clear_counters <- function() {
  .Call(covr_counter_reset)
  rm(envir = .counters, list = ls(envir = .counters))
  rm(envir = .current_test, list = ls(envir = .current_test))
}

# Set the counts of all traces to zero, keeping the traces themselves.
zero_counters <- function() {
  .Call(covr_counter_reset)
  for (key in setdiff(
    ls(.counters, all.names = TRUE),
    c("tests", "branches")
  )) {
    .counters[[key]]$value <- 0
  }
  zero_branches()
}

#' Generate a key for a  call
#'
#' @param x the srcref of the call to create a key for
#' @keywords internal
key <- function(x) {
  paste(collapse = ":", c(get_source_filename(x), x))
}

# Trace the default values of the arguments of a function whose srcref is
# `fun_ref`, with srcrefs for conditionals in them, so their branches get
# their own counters as in the body (see `impute_formal_srcrefs()`). The
# parse data is only looked up if a conditional needs it.
trace_formals <- function(x, parent_functions, fun_ref) {
  if (is.null(x) || is.null(fun_ref)) {
    return(trace_calls(x, parent_functions))
  }
  refs <- NULL
  formal_ref <- function(i) {
    force(i)
    function() {
      if (is.null(refs)) {
        refs <<- impute_formal_srcrefs(fun_ref) %||% list()
      }
      if (i <= length(refs)) refs[[i]]
    }
  }
  res <- lapply(seq_along(x), function(i) {
    trace_calls(x[[i]], parent_functions, impute_ref = formal_ref(i))
  })
  names(res) <- names(x)
  as.pairlist(res)
}
