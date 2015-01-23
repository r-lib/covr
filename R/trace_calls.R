#' trace each call with a srcref attribute
#'
#' This function calls itself recursively so it can properly traverse the AST.
#' @param x the call
#' @param srcref argument used to set the srcref of the current call when recursing
#' @seealso \url{http://adv-r.had.co.nz/Expressions.html}
#' @return a modified expression with count calls inserted before each previous
#' call.
trace_calls <- function (x, srcref = NULL) {
  recurse <- function(y) {
    lapply(y, trace_calls)
  }

  if (is.atomic(x) || is.name(x)) {
    if (length(x) == 0 || is.null(srcref)) {
      x
    }
    else {
      if ((!is.symbol(x) && is.na(x)) || as.character(x) == "{") {
        x
      } else {
        key <- key(srcref)
        covr:::new_counter(key)
        bquote(`{`(covr:::count(.(key)), .(x)))
      }
    }
  }
  else if (is.call(x)) {
    src_ref <- attr(x, "srcref")
    if (!is.null(src_ref)) {
      as.call(Map(trace_calls, x, src_ref))
    } else if (!is.null(srcref)) {
      key <- key(srcref)
      covr:::new_counter(key)
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
      key <- key(src_ref)
      covr:::new_counter(key)
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

.counters <- new.env()

#' initialize a new counter
#'
#' @param key generated with \code{\link{key}}
new_counter <- function(key) {
  .counters[[key]] <- 0
}

#' increment a given counter
#'
#' @inheritParams new_counter
count <- function(key) {
  .counters[[key]] <- .counters[[key]] + 1
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
  file <- attr(x, "srcfile")$filename %||% "<default>"
  paste(sep = ":", file, paste0(collapse = ":", c(x)))
  ## See: Issue #24 (and deprecated Pull Request #25)
  res <- paste(sep = ":", file, paste0(collapse = ":", c(x)))
  gsub("<text>", ".text.", res, fixed=TRUE)
}
