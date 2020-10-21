#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param parent_functions the functions which this call is a child of.
#' @param parent_ref argument used to set the srcref of the current call during
#'   the recursion.
#' @param traces
#' @seealso <http://adv-r.had.co.nz/Expressions.html>
#' @return a modified expression with count calls inserted before each previous
#' call.
#' @keywords internal
trace_calls <- function (x, parent_functions = NULL, parent_ref = NULL, traces = as.environment(list(n = 0L))) {

  # Construct the calls by hand to avoid a NOTE from R CMD check
  count <- function(key, val, is_first_trace = FALSE) {
    covr_call <- call(
      "{",
      as.call(list(call(":::", as.symbol("covr"), as.symbol("set_current_test")), key)),
      as.call(list(call(":::", as.symbol("covr"), as.symbol("count")), key)),
      val
    )

    traces$n <- traces$n + 1L

    # omit test trace if no parent ref or explicitly disabled
    if (traces$n > 1L) covr_call <- covr_call[-2]
    call("if", TRUE, covr_call)
  }

  if (is.null(parent_functions)) {
    parent_functions <- deparse(substitute(x))
  }

  recurse <- function(y) {
    lapply(y, trace_calls, parent_functions = parent_functions, traces = traces)
  }

  if (is.atomic(x) || is.name(x)) {
    if (is.null(parent_ref)) {
      x
    }
    else {
      if (is_na(x) || is_brace(x)) {
        x
      } else {
        key <- new_counter(parent_ref, parent_functions) # nolint
        count(key, x)
      }
    }
  }
  else if (is.call(x)) {
    src_ref <- attr(x, "srcref") %||% impute_srcref(x, parent_ref)
    if ((identical(x[[1]], as.name("<-")) || identical(x[[1]], as.name("="))) && # nolint
      (is.call(x[[3]]) && identical(x[[3]][[1]], as.name("function")))) {
      parent_functions <- c(parent_functions, as.character(x[[2]]))
    }

    # do not try to trace curly curly
    if (identical(x[[1]], as.name("{")) && length(x) == 2 && is.call(x[[2]]) && identical(x[[2]][[1]], as.name("{"))) {
      as.call(x)
    } else if (!is.null(src_ref)) {
      as.call(Map(trace_calls, x, src_ref, MoreArgs = list(parent_functions = parent_functions, traces = traces)))
    } else if (!is.null(parent_ref)) {
      key <- new_counter(parent_ref, parent_functions)
      count(key, as.call(recurse(x)))
    } else {
      as.call(recurse(x))
    }
  }
  else if (is.function(x)) {

    # We cannot trace primitive functions
    if (is.primitive(x)) {
      return(x)
    }

    fun_body <- body(x)

    if (!is.null(attr(x, "srcref")) &&
       (is.symbol(fun_body) || !identical(fun_body[[1]], as.name("{")))) {
      src_ref <- attr(x, "srcref")
      key <- new_counter(src_ref, parent_functions)
      fun_body <- count(key, trace_calls(fun_body, parent_functions, traces = traces))
    } else {
      fun_body <- trace_calls(fun_body, parent_functions, traces = traces)
    }

    new_formals <- trace_calls(formals(x), parent_functions, traces = traces)
    if (is.null(new_formals)) new_formals <- list()
    formals(x) <- new_formals
    body(x) <- fun_body
    x
  }
  else if (is.pairlist(x)) {
    as.pairlist(recurse(x))
  }
  else if (is.expression(x)) {
    as.expression(recurse(x))
  }
  else if (is.list(x)) {
    recurse(x)
  }
  else {
    message("Unknown language class: ", paste(class(x), collapse = "/"),
      call. = FALSE)
    x
  }
}

.current_test <- new.env(parent = emptyenv())
.counters <- new.env(parent = emptyenv())

#' initialize a new counter
#'
#' @param src_ref a [base::srcref()]
#' @param parent_functions the functions that this srcref is contained in.
#' @keywords internal
new_counter <- function(src_ref, parent_functions) {
  key <- key(src_ref)
  .counters[[key]]$value <- 0
  .counters[[key]]$srcref <- src_ref
  .counters[[key]]$functions <- parent_functions
  # # substantial (~15% faster) speedup if this _isnt_ instantiated
  # .counters[[key]]$testrefs <- list()    
  key
}

#' increment a given counter
#'
#' @param key generated with [key()]
#' @keywords internal
count <- function(key, log_test = FALSE) {
  .counters[[key]]$value <- .counters[[key]]$value + 1L
  if (log_test) count_test(key)
}

#' append a testref to a counter
#'
#' @param key generated with [key()]
#' @keywords internal
count_test <- function(key) {
  .counters[[key]]$testrefs <- append(
    .counters[[key]]$testrefs, 
    list(.current_test$srcref)
  )
}

#' set the current 
#'
#' @param key generated with [key()]
#' @keywords internal
set_current_test <- function(key) {
  # only execute once per set of counters
  if (is.null(.current_test$nframe)) {
    .current_test$nframe <- find_first_srcref_nframe(rootpath = getwd())
  }
  if (is.null(.current_test$nframe)) {
    .current_test$srcref <- NULL
  } else {
    .current_test$srcref <- getSrcref(sys.call(which = .current_test$nframe))
  }
}


#' clear all previous counters
#'
#' @keywords internal
clear_counters <- function() {
  rm(envir = .counters, list = ls(envir = .counters))
  clear_current_test()
}


#' clear all current test data
#'
#' @keywords internal
clear_current_test <- function() {
  rm(envir = .current_test, list = ls(envir = .current_test))
}

#' Generate a key for a  call
#'
#' @param x the srcref of the call to create a key for
#' @keywords internal
key <- function(x) {
  paste(collapse = ":", c(get_source_filename(x), x))
}

f1 <- function() {
  f2 <- function() {
    2
  }
  f2()
}
