#' @importFrom utils getParseData getSrcref tail
impute_srcref <- function(x, parent_ref) {
  if (!is_conditional_or_loop(x)) return(NULL)
  if (is.null(parent_ref)) return(NULL)

  pd <- get_tokens(parent_ref)
  pd_expr <-
    (
      (pd$line1 == parent_ref[[1L]] & pd$line2 == parent_ref[[3L]]) |
      (pd$line1 == parent_ref[[7L]] & pd$line2 == parent_ref[[8L]])
    ) &
    pd$col1 == parent_ref[[2L]] &
    pd$col2 == parent_ref[[4L]] &
    pd$token == "expr"
  pd_expr_idx <- which(pd_expr)
  if (length(pd_expr_idx) == 0L) return(NULL) # srcref not found in parse data

  if (length(pd_expr_idx) > 1) pd_expr_idx <- pd_expr_idx[[1]]

  expr_id <- pd$id[pd_expr_idx]
  pd_child <- pd[pd$parent == expr_id, ]
  pd_child <- pd_child[order(pd_child$line1, pd_child$col1), ]

  # exclude comments
  pd_child <- pd_child[pd_child$token != "COMMENT", ]

  if (pd$line1[pd_expr_idx] == parent_ref[[7L]] & pd$line2[pd_expr_idx] == parent_ref[[8L]]) {
    line_offset <- parent_ref[[7L]] - parent_ref[[1L]]
  } else {
    line_offset <- 0
  }

  make_srcref <- function(from, to = from) {
    if (length(from) == 0) {
      return(NULL)
    }

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
        make_srcref(3),
        make_srcref(5),
        make_srcref(7)
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

    "switch" = {
      exprs <- which(pd_child$token == "expr")
      exprs <- exprs[exprs >= 3]
      c(list(NULL), Map(make_srcref, from = exprs))
    },

    NULL
  )
}

is_conditional_or_loop <- function(x) is.symbol(x[[1L]]) && as.character(x[[1L]]) %in% c("if", "for", "else", "switch")

package_parse_data <- new.env()

get_parse_data <- function(srcfile) {
  if (length(package_parse_data) == 0) {
    lines <- getSrcLines(srcfile, 1L, Inf)
    res <- lapply(split_on_line_directives(lines),
      function(x) getParseData(parse(text = x, keep.source = TRUE), includeText = FALSE))
    for (i in seq_along(res)) {
      package_parse_data[[names(res)[[i]]]] <- res[[i]]
    }
  }
  package_parse_data[[srcfile[["filename"]]]]
}

clean_parse_data <- function() {
  for (nme in ls(package_parse_data)) {
    rm(nme, envir = package_parse_data)
  }
}

# Needed to work around https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16756
get_tokens <- function(srcref) {
  getParseData(srcref) %||% get_parse_data(attr(getSrcref(srcref), "srcfile"))
}
