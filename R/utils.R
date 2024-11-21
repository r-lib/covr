`%||%` <- function(x, y) {
  if (!is.null(x)) {
    x
  } else {
    y
  }
}

compact <- function(x) {
  x[viapply(x, length) != 0]
}

trim <- function(x) {
  rex::re_substitutes(x, rex::rex(list(start, spaces) %or% list(spaces, end)),  "", global = TRUE)
}

local_branch <- function(dir = ".") {
  withr::with_dir(dir,
    branch <- system_output("git", c("rev-parse", "--abbrev-ref", "HEAD"))
  )
  trim(branch)
}

current_commit <- function(dir = ".") {
  withr::with_dir(dir,
    commit <- system_output("git", c("rev-parse", "HEAD"))
  )
  trim(commit)
}

`[.coverage` <- function(x, i, ...) {
  attrs <- attributes(x)
  attrs$names <- attrs$names[i]
  res <- unclass(x)
  res <- res[i]
  attributes(res) <- attrs
  res
}

to_title <- function(x) {
  rex::re_substitutes(x,
                      rex::rex(rex::regex("\\b"), capture(any)),
                      "\\U\\1",
                      global = TRUE)
}

srcfile_lines <- function(srcfile) {
  lines <- getSrcLines(srcfile, 1, Inf)
  matches <- rex::re_matches(lines,
    rex::rex(start, any_spaces, "#line", spaces,
      capture(name = "line_number", digit), spaces,
      quotes, capture(name = "filename", anything), quotes))

  matches <- na.omit(matches)

  filename_match <- which(matches$filename == srcfile$filename)

  if (length(filename_match) == 1) {

     # rownames(matches) is the line number of lines
    start <- as.numeric(rownames(matches)[filename_match]) + 1

    # If there is another directive we want to stop at that, otherwise stop at
    # the end
    end <- if (!is.na(rownames(matches)[filename_match + 1])) {
      as.numeric(rownames(matches)[filename_match + 1]) - 1
    } else {
      length(lines)
    }

    # If there are no line directives for the file just use the entire file
  } else {
    start <- 1
    end <- length(lines)
  }

  res <- lines[seq(start, end)]

  # Track blank or comment lines so they can be excluded from the result calculations, but only for R files
  if (rex::re_matches(srcfile$filename, rex::rex(".", one_of("r", "R"), end))) {
    attr(res, "blanks") <- which(rex::re_matches(res, rex::rex(start, any_spaces, maybe("#", anything), end)))
  }
  res
}

# Split lines into a list based on the line directives in the file.
split_on_line_directives <- function(lines) {
  matches <- rex::re_matches(lines,
    rex::rex(start, any_spaces, "#line", spaces,
      capture(name = "line_number", digit), spaces,
      quotes, capture(name = "filename", anything), quotes))
  directive_lines <- which(!is.na(matches$line_number))
  if (!length(directive_lines)) {
    return(NULL)
  }

  file_starts <- directive_lines + 1
  file_ends <- c(directive_lines[-1] - 1, length(lines))
  res <- mapply(
    function(start, end) lines[start:end],
    file_starts,
    file_ends,
    SIMPLIFY = FALSE
  )
  names(res) <- na.omit(matches$filename)
  res
}

traced_files <- function(x) {
  res <- list()
  filenames <- display_name(x)
  for (i in seq_along(x)) {
    src_file <- attr(x[[i]]$srcref, "srcfile")
    filename <- filenames[[i]]

    if (filename == "") next
    if (!is.null(res[[filename]])) next

    lines <- getSrcLines(src_file, 1, Inf)
    matches <- rex::re_matches(lines,
      rex::rex(start, any_spaces, "#line", spaces,
        capture(name = "line_number", digit), spaces,
        quotes, capture(name = "filename", anything), quotes))

    matches <- na.omit(matches)

    filename_match <- which(matches$filename == src_file$filename)

    if (length(filename_match) == 1) {
      start <- as.numeric(rownames(matches)[filename_match]) + 1
      end <- if (!is.na(rownames(matches)[filename_match + 1])) {
        as.numeric(rownames(matches)[filename_match + 1]) - 1
      } else {
        length(lines)
      }
    } else {
      start <- 1
      end <- length(lines)
    }
    src_file$file_lines <- lines[seq(start, end)]

    res[[filename]] <- src_file
  }
  res
}

per_line <- function(coverage) {
  df <- as.data.frame(coverage)

  # In rare cases the source reference such as generated code onload the source
  # reference will not exists, so the first_line will be NA
  df <- df[!is.na(df$first_line), ]

  files <- traced_files(coverage)

  # Lines with only spaces or only comments
  blank_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$file_lines, rex::rex(start, any_spaces, maybe("#", anything), end)))
  })

  # lines with only })], or an else block
  empty_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$file_lines, "^(?:[[:punct:][:space:]]|else)*$"))
  })

  file_lengths <- lapply(files, function(file) {
    length(file$file_lines)
  })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
  })

  # df is sorted by file and first line ascending, so we store the maximum
  # last_line seen to detect if the previous expression contains the current
  # expression.
  max_last <- 0
  prev_filename <- ""

  for (i in seq_len(NROW(df))) {
    filename <- df[i, "filename"]
    for (line in seq(df[i, "first_line"], df[i, "last_line"])) {

      # if it is not a blank line or empty line
      if (!line %in% c(blank_lines[[filename]], empty_lines[[filename]])) {

        value <- df[i, "value"]
        # if current coverage is NA or last line < max last line
        if (is.na(res[[filename]][line]) || line < max_last || (line == max_last && res[[filename]][line] > value)) {
          res[[filename]][line] <- value
        }

        if (df[i, "filename"] != prev_filename) {
          prev_filename <- df[i, "filename"]
          max_last <- 0
        }
        if (df[i, "last_line"] > max_last) {
          max_last <- df[i, "last_line"]
        }
      }
    }
  }
  structure(
    Map(function(file, coverage) {
      structure(list(file = file, coverage = coverage), class = "line_coverage")
    },
    files, res),
    class = "line_coverages")
}

if (getRversion() < "3.2.0") {
  isNamespaceLoaded <- function(x) x %in% loadedNamespaces()
}

is_windows <- function() {
  .Platform$OS.type == "windows"
}

as_package <- function(path) {
  path <- normalize_path(path)
  if (!file.exists(path)) {
    stop("`path` is invalid: ", path, call. = FALSE)
  }
  root <- package_root(path)

  if (is.null(root)) {
    stop(sQuote(path), " does not contain a package!", call. = FALSE)
  }

  res <- read_description(file.path(root, "DESCRIPTION"))
  res$path <- root

  res
}

package_root <- function(path) {
  stopifnot(is.character(path))

  has_description <- function(path) {
    file.exists(file.path(path, "DESCRIPTION"))
  }
  is_root <- function(path) {
    identical(path, dirname(path))
  }

  path <- normalize_path(path)
  while (!is_root(path) && !has_description(path)) {
    path <- dirname(path)
  }

  if (is_root(path)) {
    NULL
  } else {
    path
  }
}

read_description <- function(path) {
  if (!length(path) || !file.exists(path)) {
    stop("DESCRIPTION file not found at ", sQuote(path), call. = FALSE)
  }

  res <- as.list(read.dcf(path)[1, ])
  names(res) <- tolower(names(res))
  res
}

clean_objects <- function(path) {
  files <- list.files(file.path(path, "src"),
                      pattern = rex::rex(".",
                        or("o", "sl", "so", "dylib",
                          "a", "dll"), end),
                      full.names = TRUE, recursive = TRUE)
  unlink(files)

  invisible(files)
}

# This is not actually an S3 method
# From http://stackoverflow.com/a/34639237/2055486
setdiff.data.frame <- function(x, y,
    by = intersect(names(x), names(y)),
    by.x = by, by.y = by) {
  stopifnot(
    is.data.frame(x),
    is.data.frame(y),
    length(by.x) == length(by.y))

  !do.call(paste, c(x[by.x], sep = "\30")) %in% do.call(paste, c(y[by.y], sep = "\30"))
}

`%==%` <- function(x, y) identical(x, y)

`%!=%` <- function(x, y) !identical(x, y)

is_na <- function(x) {
  !is.null(x) && !is.symbol(x) && is.na(x)
}

is_brace <- function(x) {
  is.symbol(x) && as.character(x) == "{"
}

modify_name <- function(expr, old, new) {
  replace <- function(e)
    if (is.name(e) && identical(e, as.name(old))) e <- as.name(new)
     else if (length(e) <= 1L) e
     else as.call(lapply(e, replace))
  replace(expr)
}


# This is the fix for https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16659
match_arg <- base::match.arg
body(match_arg) <- modify_name(body(match_arg), "all", "any")

# from https://github.com/wch/r-source/blob/2065bd3c09813949e9fa7236d167f1b7ed5c8ba3/src/library/tools/R/check.R#L4134-L4137
env_path <- function(...) {
  paths <- c(...)
  paste(paths[nzchar(paths)], collapse = .Platform$path.sep)
}

normalize_path <- function(x) {
  path <- normalizePath(x, winslash = "/", mustWork = FALSE)
  # Strip any trailing slashes as they are invalid on windows
  sub("/*$", "", path)
}

temp_dir <- function() {
  normalize_path(tempdir())
}
temp_file <- function(pattern = "file", tmpdir = temp_dir(), fileext = "") {
  normalize_path(tempfile(pattern, tmpdir, fileext))
}

get_package_name <- function(x) {
   attr(x, "package")$package %||% "coverage"
}

get_source_filename <- function(x, full.names = FALSE, unique = TRUE, normalize = FALSE) {
  res <- getSrcFilename(x, full.names, unique)
  if (length(res) == 0) {
    return("")
  }
  if (normalize) {
    return(normalize_path(res))
  }
  res
}

vcapply <- function(X, FUN, ...) vapply(X, FUN, ..., FUN.VALUE = character(1))
vdapply <- function(X, FUN, ...) vapply(X, FUN, ..., FUN.VALUE = numeric(1))
viapply <- function(X, FUN, ...) vapply(X, FUN, ..., FUN.VALUE = integer(1))
vlapply <- function(X, FUN, ...) vapply(X, FUN, ..., FUN.VALUE = logical(1))

trim_ws <- function(x) {
  x <- sub("^[ \t\r\n]+", "", x, perl = TRUE)
  sub("[ \t\r\n]+$", "", x, perl = TRUE)
}
