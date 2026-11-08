#' @importFrom utils getParseData getSrcref tail
impute_srcref <- function(x, parent_ref) {
  if (!is_conditional_or_loop(x)) {
    return(NULL)
  }
  children <- parse_children(parent_ref)
  if (is.null(children)) {
    return(NULL)
  }
  pd_child <- children$pd_child
  pd <- children$pd
  make_srcref <- children$make_srcref
  impute_conditional(x, pd, pd_child, make_srcref)
}

# Srcrefs for the components of a call without its own srcrefs, used only to
# find conditionals nested in it (e.g. `x <- if (a) b else c`), so the
# expressions in their branches get their own counters (#279).
impute_child_srcrefs <- function(x, parent_ref) {
  children <- parse_children(parent_ref)
  if (is.null(children)) {
    return(NULL)
  }
  pd_child <- children$pd_child
  make_srcref <- children$make_srcref
  token <- pd_child$token
  n <- length(token)
  if (n == 0 || any(token == "PIPE")) {
    return(NULL)
  }
  is_expr <- token == "expr"

  res <- if (token[[1]] == "FUNCTION" || token[[1]] == "'\\\\'") {
    # function definition: only the body (the last expression) is imputed
    list(NULL, NULL, make_srcref(max(which(is_expr))), NULL)[seq_along(x)]
  } else if (n == 3 && is_expr[[1]] && is_expr[[3]] && !is_expr[[2]]) {
    if (token[[2]] == "RIGHT_ASSIGN") {
      list(NULL, make_srcref(3), make_srcref(1))
    } else {
      list(NULL, make_srcref(1), make_srcref(3))
    }
  } else if (n == 2 && is_expr[[2]]) {
    list(NULL, make_srcref(2))
  } else if (n == 3 && token[[1]] == "'('" && is_expr[[2]]) {
    list(NULL, make_srcref(2))
  } else if (n >= 3 && is_expr[[1]] && token[[2]] %in% c("'('", "'['", "LBB")) {
    # function call or subset: one argument per separator
    args <- list()
    current <- NULL
    for (i in seq(3, n)) {
      if (token[[i]] %in% c("','", "')'", "']'")) {
        args[length(args) + 1L] <- list(current)
        current <- NULL
        if (token[[i]] != "','") break
      } else if (is_expr[[i]]) {
        current <- make_srcref(i)
      }
    }
    # `f()` has no arguments but still produces one empty slot
    if (identical(token[[3]], "')'")) {
      args <- list()
    }
    c(list(NULL), args)
  } else {
    NULL
  }

  if (length(res) != length(x)) {
    return(NULL)
  }
  res
}

# The srcref of the body of a function, given the srcref of the function.
impute_body_srcref <- function(fun_ref) {
  children <- parse_children(fun_ref)
  if (is.null(children)) {
    return(NULL)
  }
  is_expr <- children$pd_child$token == "expr"
  if (!any(is_expr)) {
    return(NULL)
  }
  children$make_srcref(max(which(is_expr)))
}

# Locate `parent_ref` in the parse data and return its child tokens, along with
# a function to create srcrefs for them.
parse_children <- function(parent_ref) {
  if (is.null(parent_ref)) {
    return(NULL)
  }

  pd <- get_tokens(parent_ref)
  if (is.null(pd)) {
    return(NULL)
  }
  pd_expr <-
    ((pd$line1 == parent_ref[[1L]] & pd$line2 == parent_ref[[3L]]) |
      (pd$line1 == parent_ref[[7L]] & pd$line2 == parent_ref[[8L]])) &
    pd$col1 == parent_ref[[2L]] &
    pd$col2 == parent_ref[[4L]] &
    pd$token == "expr"
  pd_expr_idx <- which(pd_expr)
  if (length(pd_expr_idx) == 0L) {
    return(NULL)
  } # srcref not found in parse data

  if (length(pd_expr_idx) > 1) {
    pd_expr_idx <- pd_expr_idx[[1]]
  }

  expr_id <- pd$id[pd_expr_idx]
  # Subset the data frame once, excluding comments, as `[.data.frame` is slow
  rows <- which(pd$parent == expr_id & pd$token != "COMMENT")
  rows <- rows[order(pd$line1[rows], pd$col1[rows])]
  pd_child <- pd[rows, ]

  # For `lhs |> call(...)` the srcref covers the whole pipe expression. Use the
  # parse data of the call on the right-hand side, with `lhs` inserted as its
  # first argument so it matches the parse data of `call(lhs, ...)`.
  if (any(pd_child$token == "PIPE")) {
    lhs <- pd_child[1L, ]
    rhs_id <- pd_child$id[[nrow(pd_child)]]
    pd_child <- pd[pd$parent == rhs_id, ]
    pd_child <- pd_child[order(pd_child$line1, pd_child$col1), ]
    pd_child <- pd_child[pd_child$token != "COMMENT", ]
    open <- which(pd_child$token == "'('")[[1L]]
    comma <- lhs
    comma$token <- "','"
    pd_child <- rbind(
      pd_child[seq_len(open), ],
      lhs,
      if (pd_child$token[[open + 1L]] != "')'") comma,
      pd_child[-seq_len(open), ]
    )
  }

  if (
    pd$line1[pd_expr_idx] == parent_ref[[7L]] &
      pd$line2[pd_expr_idx] == parent_ref[[8L]]
  ) {
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
      c(
        pd_child$line1[from] - line_offset,
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

  list(pd = pd, pd_child = pd_child, make_srcref = make_srcref)
}

impute_conditional <- function(x, pd, pd_child, make_srcref) {
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

      src_ref <- c(list(NULL), lapply(exprs, make_srcref))

      # A trailing comma (e.g. `switch(x, a = 1, )`) adds an empty argument
      # with no expression in the parse data
      length(src_ref) <- length(x)
      src_ref
    },

    NULL
  )
}

is_conditional_or_loop <- function(x) {
  is.symbol(x[[1L]]) &&
    as.character(x[[1L]]) %in% c("if", "for", "else", "switch")
}

package_parse_data <- new.env()

get_parse_data <- function(srcfile) {
  if (length(package_parse_data) == 0) {
    lines <- getSrcLines(srcfile, 1L, Inf)
    lines_split <- split_on_line_directives(lines)
    if (!length(lines_split)) {
      return(NULL)
    }

    res <- lapply(lines_split, function(x) {
      getParseData(parse(text = x, keep.source = TRUE), includeText = NA)
    })
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
