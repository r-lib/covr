#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param srcref argument used to set the srcref of the current call when recursing
#' @seealso \url{http://adv-r.had.co.nz/Expressions.html}
#' @return a modified expression with count calls inserted before each previous
#' call.
trace_calls <- function (x, parent_ref = NULL) {
  recurse <- function(y) {
    lapply(y, trace_calls)
  }

  if (is.atomic(x) || is.name(x)) {
    if (length(x) == 0 || is.null(parent_ref)) {
      x
    }
    else {
      if ((!is.symbol(x) && is.na(x)) || as.character(x) == "{") {
        x
      } else {
        key <- covr:::new_counter(parent_ref) # nolint
        bquote(`{`(covr:::count(.(key)), .(x)))
      }
    }
  }
  else if (is.call(x)) {
    src_ref <- attr(x, "srcref")
    if (!is.null(src_ref)) {
      as.call(Map(trace_calls, x, src_ref))
    } else if (!is.null(parent_ref)) {
      key <- covr:::new_counter(parent_ref)
      bquote(`{`(covr:::count(.(key)), .(as.call(recurse(x)))))
    } else {
      as.call(recurse(x))
    }
  }
  else if (is.function(x)) {
    fun_body <- body(x)

    if(!is.null(fun_body) && !is.null(attr(x, "srcref")) &&
       (is.symbol(fun_body) || fun_body[[1]] != "{")) {
      src_ref <- attr(x, "srcref")
      key <- covr:::new_counter(src_ref)
      fun_body <- bquote(`{`(covr:::count(.(key)), .(trace_calls(fun_body))))
    } else {
      fun_body <- trace_calls(fun_body)
    }

    new_formals <- trace_calls(formals(x))
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
    stop("Unknown language class: ", paste(class(x), collapse = "/"),
      call. = FALSE)
  }
}

.counters <- new.env(parent = emptyenv())

#' initialize a new counter
#'
#' @param key generated with \code{\link{key}}
new_counter <- function(src_ref) {
  key <- key(src_ref)
  .counters[[key]]$value <- 0
  .counters[[key]]$srcref <- src_ref
  key
}

#' increment a given counter
#'
#' @inheritParams new_counter
count <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1
}

#' clear all previous counters
#'
clear_counters <- function() {
  rm(envir = .counters, list=ls(envir = .counters))
}

#' Generate a key for a  call
#'
#' @param x the call to create a key for
key <- function(x) {
  src_file <- attr(x, "srcfile")
  paste(collapse = ":", c(address(src_file), x))
}
