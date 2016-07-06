`%||%` <- function(x, y) {
  if (!is.null(x)) {
    x
  } else {
    y
  }
}

compact <- function(x) {
  x[vapply(x, length, integer(1)) != 0]
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

srcfile_lines <- memoise::memoise(function(srcfile) {
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
})

traced_files <- function(x) {
  res <- list()
  filenames <- display_name(x)
  for (i in seq_along(x)) {
    src_file <- attr(x[[i]]$srcref, "srcfile")
    filename <- filenames[[i]]
    if (is.null(res[[filename]])) {
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
  }
  res
}

per_line_old <- function(coverage) {

  files <- traced_files(coverage)

  blank_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$file_lines, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })

  file_lengths <- lapply(files, function(file) {
    length(file$file_lines)
  })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  filenames <- display_name(coverage)
  for (i in seq_along(coverage)) {
    x <- coverage[[i]]
    filename <- filenames[[i]]
    value <- x$value
    for (line in seq(x$srcref[1], x$srcref[3])) {
      # if it is not a blank line
      if (!line %in% blank_lines[[filename]]) {

      # if current coverage is na or coverage is less than current coverage
        if (is.na(res[[filename]][line]) || value < res[[filename]][line]) {
          res[[filename]][line] <- value
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
# Alternative version that counts at a byte level instead of line level

per_line <- function(coverage) {

  files <- traced_files(coverage)

  blank_lines <- lapply(files, function(file) {
    which(rex::re_matches(file$file_lines, rex::rex(start, any_spaces, maybe("#", anything), end)))
    })

  file_lengths <- lapply(files, function(file) {
    length(file$file_lines)
  })

  res <- lapply(file_lengths,
    function(x) {
      rep(NA_real_, length.out = x)
    })

  filenames <- display_name(coverage)
  # Get all the reference data for each line, appending the coverage info

  ref_mx  <- rbind(
    vapply(coverage, "[[", numeric(8L), "srcref"),
    vapply(coverage, "[[", numeric(1L), "value")
  )
  # Split by file, and compute byte coverage
  # Here we assume that in srcref the first four columns are: line start,
  # byte start, line end, byte end

  ref_dat <- split(
    ref_mx, factor(
      matrix(filenames, nrow=9L, ncol=length(filenames), byrow=TRUE),
      levels=names(file_lengths)
  ) )
  ref_dat_proc <- lapply(
    seq_along(ref_dat),
    function(i) {
      r_d <- matrix(ref_dat[[i]], nrow=9L)
      file_len <- file_lengths[[i]]

      # Create a matrix that represents every byte in the file; need to know
      # largest column.  mask_mx is used to track what bytes actually have
      # data on any given line.  We waste some memory by allocating entire
      # matrix, but gain some speed in computing what bytes we need to worry
      # about

      max_col <- max(r_d[4L, ])
      single_line_exp <- which(r_d[1L, ] == r_d[3L, ])
      res_mx <- matrix(-1, nrow=max_col, ncol=file_len)
      mask_mx <- lines_mx <- matrix(0, nrow=max_col, ncol=file_len)
      line_ranges <- Map(
        seq.int, r_d[2L, single_line_exp], r_d[4L, single_line_exp]
      )
      line_start <- r_d[1L, single_line_exp]
      bytes_w_dat <- unlist(
        lapply(
          seq_along(line_ranges),
          function(i) (line_start[i]  - 1L) * max_col + line_ranges[[i]]
      ) )
      mask_mx[bytes_w_dat] <- 1

      # Mark the bytes based on coverage; recall last number is the coverage
      # value

      for(j in seq.int(ncol(r_d))) {
        dat <- r_d[, j]
        line_1 <- dat[1L]
        line_2 <- dat[3L]
        col_1 <- dat[2L]
        col_2 <- dat[4L]

        cov_range <- seq(
          (line_1 - 1L) * max_col + col_1, (line_2 - 1L) * max_col + col_2
        )
        res_mx[cov_range] <- pmax(res_mx[cov_range], dat[9L])
      }
      # which lines had zero coverage if we ignore the masks; need to track
      # these so we can highlight multi-line expressions with zero coverage

      lines_mx[res_mx == 0] <- 1
      lines_zero <- !!colSums(lines_mx)

      # compute final line coverage by finding the minimum values that did
      # actually have line coverage info; notice how we only allow coverage
      # values from single line expressions by using the mask

      res_mx[!mask_mx] <- -1
      res_mx_t <- t(res_mx)
      res_mx_t[res_mx_t < 0] <- Inf
      line_cov <- res_mx_t[cbind(seq.int(nrow(res_mx_t)), max.col(-res_mx_t))]
      line_cov[!is.finite(line_cov)] <- NA

      # For any lines that are NA but actually have zero line coverage, reset to
      # zero

      line_cov[is.na(line_cov) & lines_zero] <- 0
      line_cov
    }
  )
  structure(
    Map(function(file, coverage) {
      structure(list(file = file, coverage = coverage), class = "line_coverage")
    },
    files, ref_dat_proc),
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
