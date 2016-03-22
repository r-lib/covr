#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param parent_functions the functions which this call is a child of.
#' @param parent_ref argument used to set the srcref of the current call when recursing
#' @seealso \url{http://adv-r.had.co.nz/Expressions.html}
#' @return a modified expression with count calls inserted before each previous
#' call.
trace_calls <- function (x, parent_functions = NULL, parent_ref = NULL) {
  if (is.null(parent_functions)) {
    parent_functions <- deparse(substitute(x))
  }
  recurse <- function(y) {
    lapply(y, trace_calls, parent_functions = parent_functions)
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
        bquote(`{`(covr:::count(.(key)), .(x)))
      }
    }
  }
  else if (is.call(x)) {
    if ((identical(x[[1]], as.name("<-")) || identical(x[[1]], as.name("="))) && # nolint
        (is.call(x[[3]]) && identical(x[[3]][[1]], as.name("function")))) {
      parent_functions <- c(parent_functions, as.character(x[[2]]))
    }
    src_ref <- attr(x, "srcref") %||% impute_srcref(x, parent_ref)
    if (!is.null(src_ref)) {
      as.call(Map(trace_calls, x, src_ref, MoreArgs = list(parent_functions = parent_functions)))
    } else if (!is.null(parent_ref)) {
      key <- new_counter(parent_ref, parent_functions)
      bquote(`{`(covr:::count(.(key)), .(as.call(recurse(x)))))
    } else {
      as.call(recurse(x))
    }
  }
  else if (is.function(x)) {
    fun_body <- body(x)

    if (!is.null(attr(x, "srcref")) &&
       (is.symbol(fun_body) || !identical(fun_body[[1]], as.name("{")))) {
      src_ref <- attr(x, "srcref")
      key <- new_counter(src_ref, parent_functions)
      fun_body <- bquote(`{`(covr:::count(.(key)), .(trace_calls(fun_body, parent_functions))))
    } else {
      fun_body <- trace_calls(fun_body, parent_functions)
    }

    new_formals <- trace_calls(formals(x), parent_functions)
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

.counters <- new.env(parent = emptyenv())

#' initialize a new counter
#'
#' @param src_ref a \code{\link[base]{srcref}}
#' @param parent_functions the functions that this srcref is contained in.
new_counter <- function(src_ref, parent_functions) {
  key <- key(src_ref)
  .counters[[key]]$value <- 0
  .counters[[key]]$srcref <- src_ref
  .counters[[key]]$functions <- parent_functions
  key
}

#' increment a given counter
#'
#' @param key generated with \code{\link{key}}
count <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1
}

#' clear all previous counters
#'
clear_counters <- function() {
  rm(envir = .counters, list = ls(envir = .counters))
}

#' Generate a key for a  call
#'
#' @param x the srcref of the call to create a key for
key <- function(x) {
  paste(collapse = ":", c(utils::getSrcFilename(x), x))
}

f1 <- function() {
  f2 <- function() {
    2
  }
  f2()
}
