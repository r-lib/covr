#' Display covr results using a standalone report
#'
#' `report()` saves the coverage report as a standalone HTML file and opens it.
#' To include the report in a larger document, such as an R Markdown or Quarto
#' document, use [report_html()] instead.
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @param file The report filename.
#' @param browse whether to open a browser to view the report.
#' @returns `report()` returns the absolute path of the report file,
#'   invisibly.
#' @section Branches:
#' If branch coverage was measured with `options(covr.branch_coverage = TRUE)`
#' (see [covr.branch_coverage]), the report also shows the branches of each
#' `if` and `switch()`. The title has the percentage of branches taken after
#' the line coverage, and the list of files has a "Branches" column with the
#' percentage of the branches of each file that were taken. In the source, a
#' line with branches has the number of its branches taken out of the total,
#' e.g. `1/2`; hovering over it or focusing it shows the label and count of
#' each branch. A line with a branch that wasn't taken is shown as partly
#' covered, unless its `if` or `switch()` never ran, which leaves it missed.
#' @section Colors:
#' Covered lines are shown in green and missed lines in red. To use other
#' colors, set the `covr.report_colors` option to a named character vector of
#' R colors (anything accepted by [grDevices::col2rgb()]; transparency is
#' ignored) with elements `covered`, `missed` and/or `partial`. The colors are
#' used for the highlighted lines and the coverage bars in the file list;
#' `partial` is used for the bars of files with at least 75% but less than 90%
#' coverage, which otherwise follow `covered`, and for the partly covered lines
#' of reports with branches, which are otherwise yellow.
#'
#' [colorblind_palette] has colors that are easier to tell apart with color
#' vision deficiency:
#'
#' ```r
#' options(covr.report_colors = covr::colorblind_palette)
#' ```
#' @section Dark mode:
#' The report uses a dark theme if the browser or operating system is set to
#' prefer one. The moon (or sun) button at the top right switches between the
#' light and dark themes; the browser remembers the choice for other reports
#' until it is switched back.
#' @examples
#' \dontrun{
#' x <- package_coverage()
#' report(x)
#'
#' # Colors that are distinguishable with most kinds of color blindness
#' old <- options(covr.report_colors = colorblind_palette)
#' report(x)
#' options(old)
#' }
#' @export
# This function was originally a shiny application, but has now been converted into
# a normal static document and no longer depends on shiny.
report <- function(
  x = package_coverage(),
  file = file.path(tempdir(), paste0(get_package_name(x), "-report.html")),
  browse = interactive()
) {
  # Before `file`, which runs `package_coverage()` by default, so the colors
  # and dependencies are checked first
  html <- report_html(x)

  save_report(html, file, browse)
}

#' A coverage report to include in other documents
#'
#' `report_html()` creates the coverage report shown by [report()] as HTML that
#' can be included in a larger document, such as an R Markdown or Quarto
#' document or a page made with htmltools. Printing it in an R Markdown or
#' Quarto chunk includes the report in the document; printing it in the console
#' shows it in the viewer.
#'
#' The report takes the width of the element it is in, and its styles and
#' scripts only apply to the report, so they don't change the rest of the
#' document. A document can include several reports.
#'
#' The colors and the dark theme can be changed as described in [report()].
#'
#' @inheritParams report
#' @returns An [htmltools::tagList()], with the dependencies of the report
#'   attached.
#' @examples
#' \dontrun{
#' # In an R Markdown or Quarto chunk
#' report_html(package_coverage())
#'
#' # Save it with other content
#' htmltools::save_html(
#'   htmltools::tagList(
#'     htmltools::h1("Package review"),
#'     report_html(package_coverage())
#'   ),
#'   "review.html"
#' )
#' }
#' @export
report_html <- function(x = package_coverage()) {
  # Check the colors before running package_coverage()
  colors <- report_colors()
  check_report_installed()

  data <- to_report_data(x)

  package_name <- attr(x, "package")$package
  percentage <- sprintf("%02.2f%%", data$overall)
  if (!is.null(data$branches_overall)) {
    percentage <- with_branch_percentage(
      percentage,
      sprintf("%02.2f%%", data$branches_overall)
    )
  }

  # The tabs, the sorting of the file list and the links to the files are
  # handled by `report.js`, which is in `report_head()`
  htmltools::browsable(htmltools::tagList(
    report_head(),
    report_container(
      colors,
      report_header(paste0(package_name, " coverage - ", percentage)),
      tabset_panel(
        tab_panel("Files", file_table(data$file_stats)),
        tab_panel("Source", addHighlight(renderSourceTable(data$full)))
      ),
      branches = !is.null(data$branches_overall)
    )
  ))
}

#' A coverage report for a specific file
#'
#' `file_report()` saves the coverage of one file as a standalone HTML file and
#' opens it. `file_report_html()` creates the same report as HTML that can be
#' included in a larger document, like [report_html()].
#'
#' With branch coverage, the report shows the branches of the file as described
#' in the "Branches" section of [report()].
#'
#' @inheritParams report
#' @param file The file to report on, if `NULL`, use the first file in the
#'   coverage output.
#' @param out_file The output file
#' @returns `file_report()` returns the absolute path of the report file,
#'   invisibly.
#' @export
file_report <- function(
  x = package_coverage(),
  file = NULL,
  out_file = file.path(
    tempdir(),
    paste0(get_package_name(x), "-file-report.html")
  ),
  browse = interactive()
) {
  html <- file_report_html(x, file)

  save_report(html, out_file, browse)
}

# Saves `html`, from `report_html()` or `file_report_html()`, as the standalone
# page `file`, creating its directory, and opens it if `browse`. Returns the
# absolute path invisibly.
save_report <- function(html, file, browse) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # Paths need to be absolute for save_html to work properly
  file <- file.path(
    normalizePath(dirname(file), mustWork = TRUE),
    basename(file)
  )

  htmltools::save_html(report_page(html), file)
  if (browse) {
    viewer <- getOption("viewer", utils::browseURL)
    viewer(file)
  }
  invisible(file)
}

#' @rdname file_report
#' @returns `file_report_html()` returns an [htmltools::tagList()], with the
#'   dependencies of the report attached.
#' @export
file_report_html <- function(x = package_coverage(), file = NULL) {
  colors <- report_colors()
  check_report_installed()

  files <- display_name(x)

  if (is.null(file)) {
    file <- files[[1]]
  }
  if (length(file) != 1) {
    covr_abort("{.arg file} must be a single file name.")
  }

  x <- x[files %in% file]

  data <- to_report_data(x)

  percentage <- data$file_stats$Coverage
  if (!is.null(data$branches_overall)) {
    percentage <- with_branch_percentage(percentage, data$file_stats$Branches)
  }

  htmltools::browsable(htmltools::tagList(
    report_head(),
    report_container(
      colors,
      report_header(paste0(file, " - ", percentage)),
      addHighlight(
        renderSourceTable(data$full, "")
      ),
      branches = !is.null(data$branches_overall)
    )
  ))
}

# The coverage in the title of a report with branches, followed by the
# percentage of branches taken, as in `print()`
with_branch_percentage <- function(percentage, branches) {
  paste0(percentage, " (branches ", branches, ")")
}

check_report_installed <- function() {
  if (!is_installed("htmltools")) {
    covr_abort(c(
      "{.fn report} requires the {.pkg htmltools} package.",
      i = "Install it with {.code install.packages(\"htmltools\")}."
    ))
  }
}

# The list of files, which `report.js` sorts by the column whose header is
# clicked. The cells of the coverage column have a bar in the color of their
# level of coverage, like codecov.io. The colors are CSS variables set by
# `report_colors_css()`, so they follow the theme.
file_table <- function(stats) {
  numeric <- setdiff(names(stats), "File")
  cell <- function(col, value) {
    if (col == "File") {
      return(htmltools::tags$td(
        class = "covr-file",
        `data-sort` = value,
        htmltools::a(href = "#", class = "covr-file-link", value)
      ))
    }
    number <- as.numeric(sub("%", "", value, fixed = TRUE))
    style <- NULL
    if (col == "Coverage" && !is.na(number)) {
      level <- coverage_level(number)
      style <- sprintf(
        "background:linear-gradient(90deg, var(--covr-bar-%s) %s, transparent %s)",
        level,
        value,
        value
      )
    }
    htmltools::tags$td(
      class = "covr-num",
      style = style,
      # The values come from sprintf() or integers, so they use a decimal
      # point whatever `OutDec` is, which `Number()` in `report.js` needs
      `data-sort` = if (is.na(number)) {
        ""
      } else {
        sub("%", "", value, fixed = TRUE)
      },
      value
    )
  }
  htmltools::tags$table(
    class = "covr-file-table",
    htmltools::tags$thead(htmltools::tags$tr(
      lapply(names(stats), function(col) {
        htmltools::tags$th(
          class = if (col %in% numeric) "covr-num",
          `aria-sort` = "none",
          htmltools::tags$button(type = "button", class = "covr-sort", col)
        )
      })
    )),
    htmltools::tags$tbody(
      lapply(seq_len(nrow(stats)), function(i) {
        htmltools::tags$tr(
          lapply(names(stats), function(col) cell(col, stats[[col]][[i]]))
        )
      })
    )
  )
}

default_report_colors <- c(covered = "#5f9744", missed = "#b94947")

#' Colors for color vision deficiency
#'
#' `colorblind_palette` has colors for the `covr.report_colors` option that
#' are easier to tell apart with color vision deficiency than the default
#' green and red: blue for covered code, yellow for partial coverage and
#' vermillion for missed code, from the Okabe-Ito palette. They are used in
#' [report()], [file_report()] and the coverage percentages printed in the
#' console.
#'
#' To set the colors in your `.Rprofile` without loading covr, copy the
#' values.
#'
#' @format A named character vector with elements `covered`, `partial` and
#'   `missed`.
#' @examples
#' colorblind_palette
#' \dontrun{
#' options(covr.report_colors = covr::colorblind_palette)
#' report()
#' }
#' @export
colorblind_palette <- c(
  covered = "#0072B2",
  partial = "#F0E442",
  missed = "#D55E00"
)

report_color_names <- c("covered", "missed", "partial")

# The colors from `getOption("covr.report_colors")`, as a 3 column matrix of
# red, green and blue values (0-255), with columns `covered` and `missed`, and
# `partial` if it is set. `partial` has no default; without it, the colors of
# files with partial coverage follow the defaults or `covered`.
#
# `invalid` is called with the cli message and its environment if the colors
# are invalid, and its result is returned, so the default stops with an error.
report_colors <- function(
  colors = getOption("covr.report_colors"),
  invalid = covr_abort
) {
  if (is.null(colors)) {
    colors <- default_report_colors
  }
  nms <- names(colors)
  if (
    !is.character(colors) ||
      length(colors) == 0 ||
      length(colors) > 3 ||
      is.null(nms) ||
      !all(nms %in% report_color_names) ||
      anyDuplicated(nms) > 0 ||
      anyNA(colors)
  ) {
    return(invalid(
      c(
        "{.code covr.report_colors} must be a named character vector.",
        i = "Use the names {.val covered}, {.val missed} and/or {.val partial}, e.g. {.code c(covered = \"#0072B2\", missed = \"#E69F00\")}."
      ),
      .envir = environment()
    ))
  }

  res <- default_report_colors
  res[nms] <- colors
  res <- res[intersect(report_color_names, names(res))]

  valid <- vlapply(res, function(color) {
    tryCatch(is.matrix(grDevices::col2rgb(color)), error = function(e) FALSE)
  })
  if (!all(valid)) {
    invalid_colors <- unname(res[!valid])
    return(invalid(
      c(
        "{.code covr.report_colors} must contain valid R colors.",
        x = "Can't find color{?s} {.val {invalid_colors}}."
      ),
      .envir = environment()
    ))
  }
  rgb <- grDevices::col2rgb(res)
  colnames(rgb) <- names(res)
  rgb
}

rgb_hex <- function(rgb) {
  sprintf("#%02x%02x%02x", rgb[[1]], rgb[[2]], rgb[[3]])
}

rgb_alpha <- function(rgb, alpha) {
  sprintf("rgba(%d,%d,%d,%s)", rgb[[1]], rgb[[2]], rgb[[3]], alpha)
}

# Mix a color with a background, white by default, keeping `amount` of the
# color
rgb_tint <- function(rgb, amount, background = c(255, 255, 255)) {
  rgb_hex(round(background - (background - rgb) * amount))
}

# The background of the dark theme in report.css
dark_background <- c(33, 37, 41)

# Background colors of the coverage bars in the file list, for files with
# coverage above 90%, above 75% and below that. The tints of the default colors
# for the light theme were picked by hand.
coverage_tints <- function(colors, dark = FALSE) {
  covered <- colors[, "covered"]
  missed <- colors[, "missed"]
  if (dark) {
    tint <- function(rgb, amount) rgb_tint(rgb, amount * 3, dark_background)
  } else {
    tint <- rgb_tint
  }
  res <- c(
    high = tint(covered, 0.12),
    mid = tint(covered, 0.06),
    low = tint(missed, 0.12)
  )
  if (!dark && rgb_hex(covered) == default_report_colors[["covered"]]) {
    res[c("high", "mid")] <- c("#edfde7", "#f9ffe5")
  }
  if (!dark && rgb_hex(missed) == default_report_colors[["missed"]]) {
    res[["low"]] <- "#fcece9"
  }
  if ("partial" %in% colnames(colors)) {
    res[["mid"]] <- tint(colors[, "partial"], 0.12)
  }
  res
}

# CSS variables with the colors of the coverage bars, for the light theme and
# the dark one
coverage_tints_css <- function(colors, selector) {
  vars <- function(tints) {
    paste0("  --covr-bar-", names(tints), ":", tints, ";\n", collapse = "")
  }
  paste0(
    selector,
    "{\n",
    vars(coverage_tints(colors)),
    "}\n",
    "html.covr-dark ",
    selector,
    "{\n",
    vars(coverage_tints(colors, dark = TRUE)),
    "}\n"
  )
}

# The class of the reports using `colors`, so a document can include reports
# with different colors
report_colors_class <- function(colors) {
  paste0("covr-colors-", digest::digest(colors, algo = "crc32"))
}

# The styles of the lines with `colors`. Reports with branches also style the
# partly covered lines, in the `partial` color if it is set, otherwise
# `default_partial_line_color`, and the branches that weren't taken.
report_colors_css <- function(colors, branches = FALSE) {
  selector <- paste0(".covr-report.", report_colors_class(colors))
  line_colors <- colors[, c("covered", "missed"), drop = FALSE]
  if (branches) {
    partial <- if ("partial" %in% colnames(colors)) {
      colors[, "partial"]
    } else {
      grDevices::col2rgb(default_partial_line_color)[, 1]
    }
    line_colors <- cbind(line_colors, partial = partial)
  }
  rules <- vapply(
    colnames(line_colors),
    function(type) {
      rgb <- line_colors[, type]
      hex <- rgb_hex(rgb)
      paste0(
        selector,
        " table tr.",
        type,
        " td{\n  background-color:",
        rgb_alpha(rgb, 0.3),
        "\n}\n",
        selector,
        " table tr:hover.",
        type,
        " .num{\n  background-color:",
        rgb_alpha(rgb, 0.7),
        "\n}\n",
        selector,
        " table tr.",
        type,
        ":hover td{\n",
        "  -webkit-box-shadow:0 -2px 0 0 ",
        hex,
        " inset;\n",
        "  -moz-box-shadow:0 -2px 0 0 ",
        hex,
        " inset;\n",
        "  box-shadow:0 -2px 0 0 ",
        hex,
        " inset\n}\n"
      )
    },
    character(1)
  )
  if (branches) {
    rules <- c(
      rules,
      paste0(
        selector,
        " .covr-branch-missed{\n  background-color:",
        rgb_alpha(colors[, "missed"], 0.3),
        "\n}\n"
      )
    )
  }
  htmltools::tags$style(htmltools::HTML(paste0(
    paste(rules, collapse = ""),
    coverage_tints_css(colors, selector)
  )))
}

# The color of partly covered lines if `covr.report_colors` has no `partial`
# color, yellow like partial coverage in the console
default_partial_line_color <- "#d4a72c"

# The element of a report, with the styles of its colors, which only apply to
# it, as the colors of other reports in the same document can differ
report_container <- function(colors, ..., branches = FALSE) {
  htmltools::div(
    class = paste("covr-report", report_colors_class(colors)),
    report_colors_css(colors, branches),
    ...
  )
}

# The styles and scripts shared by the reports, including the script that
# picks the light or dark theme, which is in the <head> so the page is never
# shown in the wrong theme. As a dependency, they are included once in a
# document with several reports, and R Markdown keeps them, which it doesn't do
# with `tags$head()`.
report_head <- function() {
  htmltools::attachDependencies(
    htmltools::tagList(),
    htmltools::htmlDependency(
      name = "covr-report",
      version = as.character(utils::packageVersion("covr")),
      src = system.file("www", package = "covr"),
      script = c("theme.js", "report.js"),
      stylesheet = "report.css",
      all_files = FALSE
    )
  )
}

report_header <- function(title) {
  htmltools::div(
    class = "covr-header",
    htmltools::h2(title),
    htmltools::tags$button(
      type = "button",
      class = "covr-theme-toggle",
      `aria-pressed` = "false",
      `aria-label` = "Dark mode",
      title = "Toggle dark mode",
      htmltools::HTML(theme_icons)
    )
  )
}

# The moon is shown in the light theme and the sun in the dark one. The moon is
# a path rather than a masked circle, as the id of a mask would be repeated in
# a document with several reports.
theme_icons <- paste0(
  '<svg class="covr-icon-moon" aria-hidden="true" width="16" height="16" ',
  'viewBox="0 0 16 16"><path fill="currentColor" ',
  'd="M8.14 1.5A6.5 6.5 0 1 0 14.5 7.86A4.5 4.5 0 0 1 8.14 1.5Z"/></svg>',
  '<svg class="covr-icon-sun" aria-hidden="true" width="16" height="16" ',
  'viewBox="0 0 16 16"><circle cx="8" cy="8" r="3.2" fill="currentColor"/>',
  '<path stroke="currentColor" stroke-width="1.5" stroke-linecap="round" ',
  'd="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3 3l1.1 1.1M11.9 11.9 13 13',
  'M3 13l1.1-1.1M11.9 4.1 13 3"/></svg>'
)

to_report_data <- function(x) {
  coverages <- per_line(x)

  res <- list()
  res$overall <- percent_coverage(x)
  res$full <- lapply(coverages, function(coverage) {
    lines <- coverage$file$file_lines
    values <- coverage$coverage
    values[is.na(values)] <- ""
    data.frame(
      line = seq_along(lines),
      source = lines,
      coverage = values,
      stringsAsFactors = FALSE
    )
  })
  nms <- names(coverages)

  # set a temp name if it doesn't exist
  nms[nms == ""] <- "<text>"

  names(res$full) <- nms

  branches <- tally_coverage(x, by = "branch")
  if (NROW(branches)) {
    res$branches_overall <- sum(branches$value > 0, na.rm = TRUE) /
      NROW(branches) *
      100
    res$full <- add_branch_lines(res$full, report_branch_lines(branches))
  }

  res$file_stats <- compute_file_stats(res$full)

  res$file_stats$File <- names(res$full)

  res$file_stats <- sort_file_stats(res$file_stats)

  res
}

# The branches on each line with branches, from the branch tally `df` (sorted
# by file, line, column and branch): the number of branches `taken`, the
# `total` number of branches, and `html`, the marker shown in the hits column
# of the report, e.g. `1/2`, with the label and count of each branch, which
# are shown when it is hovered or focused. The `if` and `switch()` calls after
# the first on a line start with a `covr-branch-next` class.
report_branch_lines <- function(df) {
  taken <- !is.na(df$value) & df$value > 0
  next_decision <- branch_blocks(df) > 0 & df$branch == 1L
  items <- paste0(
    "<span class=\"covr-branch",
    ifelse(next_decision, " covr-branch-next", ""),
    ifelse(taken, "", " covr-branch-missed"),
    "\">",
    htmltools::htmlEscape(df$label),
    ": ",
    sprintf("%.0f", df$value),
    "</span>"
  )
  key <- paste(df$filename, df$line, sep = "\r")
  lines <- unique(key)
  idx <- match(key, lines)
  first <- match(seq_along(lines), idx)
  n_taken <- tabulate(idx[taken], length(lines))
  n_total <- tabulate(idx, length(lines))
  details <- vapply(
    split(items, factor(idx, levels = seq_along(lines))),
    paste,
    character(1),
    collapse = ""
  )
  data.frame(
    filename = df$filename[first],
    line = df$line[first],
    taken = n_taken,
    total = n_total,
    html = paste0(
      "<span class=\"covr-branches\" tabindex=\"0\">",
      n_taken,
      "/",
      n_total,
      "<span class=\"covr-branch-detail\">",
      unname(details),
      "</span></span>"
    ),
    stringsAsFactors = FALSE
  )
}

# Adds the columns `taken`, `total` and `branches` (the marker of the branches
# of the line, or "") from `report_branch_lines()` to the lines of each file.
add_branch_lines <- function(full, branch_lines) {
  Map(
    function(lines, file) {
      rows <- branch_lines[branch_lines$filename == file, , drop = FALSE]
      rows <- rows[rows$line <= NROW(lines), , drop = FALSE]
      lines$taken <- rep(NA_integer_, NROW(lines))
      lines$total <- rep(NA_integer_, NROW(lines))
      lines$branches <- rep("", NROW(lines))
      lines$taken[rows$line] <- rows$taken
      lines$total[rows$line] <- rows$total
      lines$branches[rows$line] <- rows$html
      lines
    },
    full,
    names(full)
  )
}

compute_file_stats <- function(files) {
  if (length(files) == 0) {
    return(data.frame(
      Coverage = character(),
      Lines = integer(),
      Relevant = integer(),
      Covered = integer(),
      Missed = integer(),
      `Hits / Line` = character(),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }
  do.call(
    "rbind",
    lapply(files, function(file) {
      stats <- data.frame(
        Coverage = sprintf(
          "%.2f%%",
          sum(file$coverage > 0) / sum(file$coverage != "") * 100
        ),
        Lines = NROW(file),
        Relevant = sum(file$coverage != ""),
        Covered = sum(file$coverage > 0),
        Missed = sum(file$coverage == 0),
        `Hits / Line` = sprintf(
          "%.0f",
          sum(as.numeric(file$coverage), na.rm = TRUE) /
            sum(file$coverage != "")
        ),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      # The percentage of branches taken, or nothing for a file without
      # branches in a report with branches
      if (!is.null(file$total)) {
        total <- sum(file$total, na.rm = TRUE)
        stats$Branches <- if (total > 0) {
          sprintf("%.2f%%", sum(file$taken, na.rm = TRUE) / total * 100)
        } else {
          ""
        }
      }
      stats
    })
  )
}

sort_file_stats <- function(stats) {
  stats[
    order(as.numeric(sub("%", "", stats$Coverage)), -stats$Relevant),
    c(
      "File",
      "Lines",
      "Relevant",
      "Covered",
      "Missed",
      "Hits / Line",
      if (!is.null(stats$Branches)) "Branches",
      "Coverage"
    )
  ]
}

renderSourceTable <- function(data, class = "covr-hidden") {
  class_attr <- htmltools::htmlEscape(class, attribute = TRUE)
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
      if (!is.null(lines$total)) {
        type <- branch_line_type(type, lines$taken, lines$total)
        value <- paste0(value, lines$branches)
      }
      # `paste0()` would make one empty row from zero-length columns
      rows <- if (NROW(lines) == 0) {
        ""
      } else {
        paste0(
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
      }
      paste0(
        "<div data-file=\"",
        htmltools::htmlEscape(file, attribute = TRUE),
        "\" class=\"",
        class_attr,
        "\"><table class=\"table-condensed\"><tbody>\n",
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
    "\n<script>",
    "(function(script) {
  var files = script ? script.parentNode : document;
  files.querySelectorAll('div.covr-files pre').forEach(function(block) {
    covrHljs.highlightElement(block);
  });
})(document.currentScript);",
    "</script></div>"
  ))
}

# The type of each line of a report with branches, from its `type` from line
# coverage and the number of its branches `taken` out of `total` (`NA` for
# lines without branches). A line with a branch that wasn't taken is partly
# covered, like on Codecov, unless none of its branches were taken and it
# wasn't run, as an `if` or `switch()` that never ran is a missed line. Lines
# with branches but no line coverage get their type from the branches.
branch_line_type <- function(type, taken, total) {
  has_branches <- !is.na(total)
  partial <- has_branches &
    taken < total &
    (taken > 0 | type == "covered")
  never <- has_branches & !partial & type == "never"
  type[never] <- ifelse(taken[never] > 0, "covered", "missed")
  type[partial] <- "partial"
  type
}

# covr's copy of highlight.js (see `inst/www/shared/highlight.js/README.md`)
# sets `covrHljs` rather than `hljs`, so it doesn't replace the version used by
# a document that includes a report. Its colors are in `report.css`.
addHighlight <- function(x = list()) {
  highlight <- htmltools::htmlDependency(
    "covr-highlight.js",
    "11.11.1",
    system.file(package = "covr", "www/shared/highlight.js"),
    script = "highlight.min.js"
  )

  htmltools::attachDependencies(
    x,
    c(htmltools::htmlDependencies(x), list(highlight))
  )
}

rstudio_active_project <- function() rstudioapi::getActiveProject() # nocov

addin_report <- function() {
  pkg <- as_package(rstudio_active_project() %||% getwd())
  message("Calculating test coverage for ", pkg$package, "...")

  report(package_coverage(pkg$path))
}

tab_panel <- function(title, ...) {
  list(title = title, content = list(...))
}

# The page of a standalone report, with a centered column on wide screens
report_page <- function(...) {
  htmltools::tagList(
    htmltools::tags$head(htmltools::tags$meta(
      name = "viewport",
      content = "width=device-width, initial-scale=1"
    )),
    htmltools::includeCSS(system.file("www/page.css", package = "covr")),
    htmltools::div(class = "covr-page", ...)
  )
}

# The tabs of the report, which are switched by `report.js`, so the report
# doesn't need Bootstrap
tabset_panel <- function(...) {
  tabs <- list(...)
  active <- function(i) if (i == 1) "active"
  htmltools::div(
    class = "covr-tabset",
    htmltools::tags$ul(
      class = "covr-tabs",
      lapply(seq_along(tabs), function(i) {
        htmltools::tags$li(
          class = active(i),
          htmltools::a(
            href = "#",
            `data-value` = tabs[[i]]$title,
            tabs[[i]]$title
          )
        )
      })
    ),
    htmltools::div(
      class = "covr-tab-content",
      lapply(seq_along(tabs), function(i) {
        htmltools::div(
          class = paste(c("covr-tab-pane", active(i)), collapse = " "),
          `data-value` = tabs[[i]]$title,
          tabs[[i]]$content
        )
      })
    )
  )
}
