# Microbenchmarks of covr's post-processing, with prototypes of the faster
# alternatives proposed in performance-audit.md. The prototypes only live in
# this script; they are not part of covr.
#
# Usage: R_LIBS=<covr main lib>:<deps> Rscript --no-init-file \
#   performance-audit/microbench-post.R <pkg-coverage.rds>

invisible(suppressPackageStartupMessages(loadNamespace("covr")))
args <- commandArgs(trailingOnly = TRUE)
cov <- readRDS(args[[1]])

time <- function(label, expr, reps = 3) {
  # Evaluate the expression afresh in each repetition; a promise would only be
  # evaluated in the first.
  expr <- substitute(expr)
  env <- parent.frame()
  t <- median(vapply(
    seq_len(reps),
    function(i) {
      system.time(eval(expr, env))[["elapsed"]]
    },
    numeric(1)
  ))
  cat(sprintf("%-66s %8.3f s\n", label, t))
  invisible(t)
}

files <- covr:::traced_files(cov)
all_lines <- getSrcLines(attr(cov[[1]]$srcref, "srcfile"), 1, Inf)
cat(sprintf(
  "%d traces, %d files, %d lines in the concatenated package source\n\n",
  length(cov),
  length(files),
  length(all_lines)
))

# traced_files() reads and regex-splits the whole concatenated source once per
# file; splitting it once gives the same lines.
time(
  "traced_files() (current: whole source split once per file)",
  covr:::traced_files(cov)
)
split_once <- function(x) {
  filenames <- covr:::display_name(x)
  originals <- new.env()
  res <- list()
  for (i in seq_along(x)) {
    filename <- filenames[[i]]
    if (filename == "" || !is.null(res[[filename]])) {
      next
    }
    src_file <- attr(x[[i]]$srcref, "srcfile")
    original <- src_file$original %||% src_file
    id <- covr:::address(original)
    if (is.null(originals[[id]])) {
      lines <- getSrcLines(src_file, 1, Inf)
      originals[[id]] <- covr:::split_on_line_directives(lines) %||% list(lines)
    }
    split <- originals[[id]]
    src_file$file_lines <- split[[src_file$filename]] %||% split[[1]]
    res[[filename]] <- src_file
  }
  res
}
`%||%` <- function(x, y) if (is.null(x)) y else x
time("prototype: split the concatenated source once", split_once(cov))
proto <- split_once(cov)
stopifnot(identical(
  lapply(files, function(f) f$file_lines),
  lapply(proto[names(files)], function(f) f$file_lines)
))

# non_code_lines(): rex::re_matches() vs grepl() with the same patterns.
lines <- lapply(files, function(f) f$file_lines)
time(
  "non_code_lines() regexes via rex::re_matches()",
  lapply(lines, function(l) {
    which(
      rex::re_matches(
        l,
        rex::rex(start, any_spaces, maybe("#", anything), end)
      ) |
        rex::re_matches(l, "^(?:[[:punct:][:space:]]|else)*$")
    )
  })
)
time(
  "prototype: the same regexes via grepl(perl = TRUE)",
  lapply(lines, function(l) {
    which(
      grepl("^[[:space:]]*(?:#.*)?$", l, perl = TRUE) |
        grepl("^(?:[[:punct:][:space:]]|else)*$", l, perl = TRUE)
    )
  })
)
stopifnot(identical(
  lapply(lines, function(l) {
    which(
      rex::re_matches(
        l,
        rex::rex(start, any_spaces, maybe("#", anything), end)
      ) |
        rex::re_matches(l, "^(?:[[:punct:][:space:]]|else)*$")
    )
  }),
  lapply(lines, function(l) {
    which(
      grepl("^[[:space:]]*(?:#.*)?$", l, perl = TRUE) |
        grepl("^(?:[[:punct:][:space:]]|else)*$", l, perl = TRUE)
    )
  })
))

# report(): the source tab has a <tr> with three cells for every line of every
# file, built as htmltools tags; rendering them dominates report(). The
# prototype builds the same table rows as strings.
data <- covr:::to_report_data(cov)
time(
  "to_report_data() (per_line() + percent_coverage())",
  covr:::to_report_data(cov),
  reps = 1
)
n_lines <- sum(vapply(data$full, nrow, integer(1)))
cat(sprintf("source table rows: %d\n", n_lines))
time(
  "renderSourceTable() + renderTags() (current)",
  htmltools::renderTags(covr:::renderSourceTable(data$full)),
  reps = 1
)
source_table_html <- function(data) {
  files <- Map(
    function(lines, file) {
      cov <- lines$coverage
      type <- ifelse(
        cov == "",
        "never",
        ifelse(cov == "0", "missed", "covered")
      )
      value <- ifelse(
        cov == "",
        "",
        ifelse(cov == "0", "!", paste0(cov, "<em>x</em>"))
      )
      rows <- paste0(
        "<tr class=\"",
        type,
        "\"><td class=\"num\">",
        lines$line,
        "</td><td class=\"coverage\">",
        value,
        "</td><td class=\"covr-source\"><pre class=\"language-r\">",
        htmltools::htmlEscape(lines$source),
        "</pre></td></tr>",
        collapse = "\n"
      )
      paste0(
        "<div data-file=\"",
        htmltools::htmlEscape(file, attribute = TRUE),
        "\" class=\"covr-hidden\"><table class=\"table-condensed\"><tbody>\n",
        rows,
        "\n</tbody></table></div>"
      )
    },
    data,
    names(data)
  )
  htmltools::HTML(paste0(
    "<div class=\"covr-files\">",
    paste(files, collapse = "\n"),
    "</div>"
  ))
}
time(
  "prototype: source table as strings + renderTags()",
  htmltools::renderTags(source_table_html(data$full)),
  reps = 3
)
