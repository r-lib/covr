repair_parse_data <- function(env) {
  srcref <- lapply(as.list(env), attr, "srcref")
  srcfile <- lapply(srcref, attr, "srcfile")
  parse_data <- compact(lapply(srcfile, "[[", "parseData"))
  if (length(parse_data) == 0L) {
    warning(paste("Parse data not found, coverage may be inaccurate. Try",
                  "declaring a function in the last file of your R package."),
            call. = FALSE)
    return()
  }

  if (!all_identical(parse_data)) {
    warning("Ambiguous parse data, coverage may be inaccurate.",
            call. = FALSE)
  }

  original <- compact(lapply(srcfile, "[[", "original"))
  if (!all_identical(parse_data)) {
    warning("Ambiguous original file, coverage may be inaccurate.",
            call. = FALSE)
  }

  original[[1]][["parseData"]] <- parse_data[[1L]]
}

impute_srcref <- function(x, parent_ref) {
  if (!is_conditional_or_loop(x)) return(NULL)
  if (is.null(parent_ref)) return(NULL)

  pd <- getParseData(parent_ref, includeText = FALSE)
  pd_expr <-
    pd$line1 == parent_ref[[7L]] &
    pd$col1 == parent_ref[[2L]] &
    pd$line2 == parent_ref[[8L]] &
    pd$col2 == parent_ref[[4L]] &
    pd$token == "expr"
  pd_expr_idx <- which(pd_expr)
  if (length(pd_expr_idx) == 0L) return(NULL) # srcref not found in parse data

  stopifnot(length(pd_expr_idx) == 1L)
  expr_id <- pd$id[pd_expr_idx]
  pd_child <- pd[pd$parent == expr_id, ]

  line_offset <- parent_ref[[7L]] - parent_ref[[1L]]

  make_srcref <- function(from, to = from) {
    srcref(
      attr(parent_ref, "srcfile"),
      c(pd_child$line1[from] - line_offset,
        pd_child$col1[from],
        pd_child$line2[to] - line_offset,
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
      # the fourth component isn't used for an "if" without "else"
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

    NULL
  )
}

is_conditional_or_loop <- function(x) is.symbol(x[[1L]]) && as.character(x[[1L]]) %in% c("if", "for", "else")
