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
  rex::re_substitutes(
    x,
    rex::rex(list(start, spaces) %or% list(spaces, end)),
    "",
    global = TRUE
  )
}

local_branch <- function(dir = ".") {
  withr::with_dir(
    dir,
    branch <- system_output("git", c("rev-parse", "--abbrev-ref", "HEAD"))
  )
  trim(branch)
}

current_commit <- function(dir = ".") {
  withr::with_dir(dir, commit <- system_output("git", c("rev-parse", "HEAD")))
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
  rex::re_substitutes(
    x,
    rex::rex(rex::regex("\\b"), capture(any)),
    "\\U\\1",
    global = TRUE
  )
}

# Split lines into a list based on the line directives in the file.
split_on_line_directives <- function(lines) {
  matches <- rex::re_matches(
    lines,
    rex::rex(
      start,
      any_spaces,
      "#line",
      spaces,
      capture(name = "line_number", digit),
      spaces,
      quotes,
      capture(name = "filename", anything),
      quotes
    )
  )
  directive_lines <- which(!is.na(matches$line_number))
  if (!length(directive_lines)) {
    return(NULL)
  }

  file_starts <- directive_lines + 1
  file_ends <- c(directive_lines[-1] - 1, length(lines))
  # An empty file has no lines between its directive and the next one (or the
  # end), so `file_ends` is one less than `file_starts` (#522)
  res <- mapply(
    function(start, end) lines[seq.int(start, length.out = end - start + 1)],
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

    if (filename == "") {
      next
    }
    if (!is.null(res[[filename]])) {
      next
    }

    lines <- getSrcLines(src_file, 1, Inf)
    matches <- rex::re_matches(
      lines,
      rex::rex(
        start,
        any_spaces,
        "#line",
        spaces,
        capture(name = "line_number", digit),
        spaces,
        quotes,
        capture(name = "filename", anything),
        quotes
      )
    )

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
  files <- traced_files(coverage)
  lines <- collapse_lines(tally_coverage(coverage, by = "line"))

  structure(
    Map(
      function(file, filename) {
        values <- rep(NA_real_, length.out = length(file$file_lines))
        file_lines <- lines[lines$filename == filename, , drop = FALSE]
        values[file_lines$line] <- file_lines$value
        structure(
          list(file = file, coverage = values),
          class = "line_coverage"
        )
      },
      files,
      names(files)
    ),
    class = "line_coverages"
  )
}

is_windows <- function() {
  .Platform$OS.type == "windows"
}

# Signal errors and warnings formatted by cli without needing rlang. `message`
# is a cli bullet vector interpolated in `.envir`; `output` lines (e.g. from an
# external command or server) are appended as is; `...` adds condition fields.
covr_abort <- function(
  message,
  ...,
  output = NULL,
  class = NULL,
  .envir = parent.frame()
) {
  stop(structure(
    list(
      message = cnd_message(cli::format_error, message, output, .envir),
      call = NULL,
      ...
    ),
    class = c(class, "error", "condition")
  ))
}

covr_warn <- function(
  message,
  ...,
  output = NULL,
  class = NULL,
  .envir = parent.frame()
) {
  warning(structure(
    list(
      message = cnd_message(cli::format_warning, message, output, .envir),
      call = NULL,
      ...
    ),
    class = c(class, "warning", "condition")
  ))
}

cnd_message <- function(format, message, output, .envir) {
  paste(c(format(message, .envir = .envir), output), collapse = "\n")
}

as_package <- function(path) {
  path <- normalize_path(path)
  if (!file.exists(path)) {
    covr_abort(c(
      "{.arg path} must be an existing directory.",
      x = "{.path {path}} doesn't exist."
    ))
  }
  root <- package_root(path)

  if (is.null(root)) {
    covr_abort("Can't find a package in {.path {path}}.")
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

is_installed_package <- function(path) {
  file.exists(file.path(path, "Meta", "package.rds"))
}

# The directory of the source an installed package was installed from, the
# parent of the `R` directory with the files in the srcrefs of its traces, or
# `NULL` if it was installed without srcrefs. The namespace can also have
# functions with srcrefs from elsewhere, e.g. other packages, so this is the
# directory with the most traces.
installed_source_path <- function(traces) {
  files <- vcapply(traces, function(x) {
    get_source_filename(x$srcref, full.names = TRUE)
  })
  files <- files[grepl("/R/", files, fixed = TRUE)]
  if (length(files) == 0) {
    return(NULL)
  }
  dirs <- sub("^(.*)/R/.*$", "\\1", files)
  names(which.max(table(dirs)))
}

read_description <- function(path) {
  if (!length(path) || !file.exists(path)) {
    covr_abort("Can't find a DESCRIPTION file at {.path {path}}.")
  }

  res <- as.list(read.dcf(path)[1, ])
  names(res) <- tolower(names(res))
  res
}

clean_objects <- function(path) {
  files <- list.files(
    file.path(path, "src"),
    pattern = rex::rex(".", or("o", "sl", "so", "dylib", "a", "dll"), end),
    recursive = TRUE
  )
  # cargo rebuilds what it needs, but doesn't notice when the libraries built
  # by build scripts (e.g. savvy's) are removed from its `target` directory, so
  # leave the directories of Rust code's dependencies and build output alone.
  if (length(rust_manifests(path))) {
    files <- files[!in_rust_dependency_dir(files)]
  }
  files <- file.path(path, "src", files)
  unlink(files)

  invisible(files)
}

# This is not actually an S3 method
# From http://stackoverflow.com/a/34639237/2055486
setdiff.data.frame <- function(
  x,
  y,
  by = intersect(names(x), names(y)),
  by.x = by,
  by.y = by
) {
  stopifnot(
    is.data.frame(x),
    is.data.frame(y),
    length(by.x) == length(by.y)
  )

  !do.call(paste, c(x[by.x], sep = "\30")) %in%
    do.call(paste, c(y[by.y], sep = "\30"))
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
  replace <- function(e) {
    if (is.name(e) && identical(e, as.name(old))) {
      e <- as.name(new)
    } else if (length(e) <= 1L) {
      e
    } else {
      as.call(lapply(e, replace))
    }
  }
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

is_absolute_path <- function(x) {
  grepl("^(/|~|[A-Za-z]:|\\\\\\\\)", x)
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

get_source_filename <- function(
  x,
  full.names = FALSE,
  unique = TRUE,
  normalize = FALSE
) {
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
