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
    if (length(x) == 0 || is.null(parent_ref)) {
      x
    }
    else {
      if ((!is.symbol(x) && is.na(x)) || as.character(x) == "{") { # nolint
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

    if (!is.null(fun_body) && !is.null(attr(x, "srcref")) &&
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
  src_file <- attr(x, "srcfile")
  paste(collapse = ":", c(address(src_file), x))
}

f1 <- function() {
  f2 <- function() {
    2
  }
  f2()
}

impute_srcref <- function(x, parent_ref) {
  if (is.null(parent_ref)) return(NULL)
  pd <- getParseData(parent_ref)
  pd_expr <-
    pd$line1 == parent_ref[[1L]] &
    pd$col1 == parent_ref[[2L]] &
    pd$line2 == parent_ref[[3L]] &
    pd$col2 == parent_ref[[4L]] &
    pd$token == "expr"
  pd_expr_idx <- which(pd_expr)
  if (length(pd_expr_idx) == 0L) return(NULL) # srcref not found in parse data

  stopifnot(length(pd_expr_idx) == 1L)
  expr_id <- pd$id[pd_expr_idx]
  pd_child <- pd[pd$parent == expr_id,]

  make_srcref <- function(from, to = from) {
    srcref(
      attr(parent_ref, "srcfile"),
      c(pd_child$line1[from],
        pd_child$col1[from],
        pd_child$line2[to],
        pd_child$col2[to],
        pd_child$col1[from],
        pd_child$col2[to],
        pd_child$line1[from],
        pd_child$line2[to]
      ))
  }

  switch(
    as.character(x[[1L]]),
    "if" = {
      src_ref <- list(
        NULL,
        make_srcref(2, 4),
        make_srcref(5),
        make_srcref(6, 7)
      )
      src_ref[seq_along(x)]
    },

    "for" = {
      list(
        NULL,
        NULL,
        make_srcref(2),
        make_srcref(3)
      )
    },

    "while" = {
      list(
        NULL,
        make_srcref(3),
        make_srcref(5)
      )
    },

    "repeat" = {
      list(
        NULL,
        make_srcref(2)
      )
    },

    NULL
  )
}
