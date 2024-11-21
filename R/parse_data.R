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
      )
    )
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
      exprs <- tail(which(pd_child$token == "expr"), n = -1)

      # Add NULLs for drop through conditions
      token <- pd_child$token
      next_token <- c(tail(token, n = -1), NA_character_)
      drops <- which(token == "EQ_SUB" & next_token != "expr")

      exprs <- sort(c(exprs, drops))

      ignore_drop_through <- function(x) {
        if (x %in% drops) {
          return(NULL)
        }
        x
      }

      exprs <- lapply(exprs, ignore_drop_through)

      # Don't create srcrefs for ... conditions
      ignore_dots <- function(x) {
        if (identical("...", pd$text[pd$parent == pd_child$id[x]])) {
          return(NULL)
        }
        x
      }

      exprs <- lapply(exprs, ignore_dots)

      c(list(NULL), lapply(exprs, make_srcref))
    },

    NULL
  )
}

is_conditional_or_loop <- function(x) is.symbol(x[[1L]]) && as.character(x[[1L]]) %in% c("if", "for", "else", "switch")

package_parse_data <- new.env()

get_parse_data <- function(srcfile) {
  if (length(package_parse_data) == 0) {
    lines <- getSrcLines(srcfile, 1L, Inf)
    lines_split <- split_on_line_directives(lines)
    if (!length(lines_split)) {
      return(NULL)
    }

    res <- lapply(lines_split,
      function(x) getParseData(parse(text = x, keep.source = TRUE), includeText = TRUE))
    for (i in seq_along(res)) {
      package_parse_data[[names(res)[[i]]]] <- res[[i]]
    }
  }
  package_parse_data[[srcfile[["filename"]]]]
}

clean_parse_data <- function() {
  rm(list = ls(package_parse_data), envir = package_parse_data)
}

get_tokens <- function(srcref) {
  # Before R 4.4.0, covr's custom get_parse_data is necessary because
  # utils::getParseData returns parse data for only the last file in the
  # package. That issue (bug#16756) is fixed in R 4.4.0 (r84538).
  #
  # On R 4.4.0, continue to use get_parse_data because covr's code expects the
  # result to be limited to the srcref file. getParseData will return parse data
  # for all of the package's files.
  get_parse_data(attr(getSrcref(srcref), "srcfile")) %||%
    # This covers the non-installed file case where the source file isn't a
    # concatenated file with "line N" directives.
    getParseData(srcref)
}
