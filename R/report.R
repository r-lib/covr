#' Display covr results using a standalone report
#'
#' `report()` saves the coverage report as a standalone HTML file and opens it.
#' To include the report in a larger document, such as an R Markdown or Quarto
#' document, use [report_html()] instead.
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @param file The report filename.
#' @param browse whether to open a browser to view the report.
#' @section Colors:
#' Covered lines are shown in green and missed lines in red. To use other
#' colors, e.g. a pair that is easier to tell apart with color vision
#' deficiency, set the `covr.report_colors` option to a named character vector
#' of R colors (anything accepted by [grDevices::col2rgb()]; transparency is
#' ignored) with elements `covered`, `missed` and/or `partial`. The colors are
#' used for the highlighted lines and the coverage bars in the file list;
#' `partial` is used for the bars of files with at least 75% but less than 90%
#' coverage, which otherwise follow `covered`.
#'
#' ```r
#' options(covr.report_colors = c(covered = "#0072B2", missed = "#E69F00"))
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
#' # Blue and orange, which are distinguishable with most kinds of color
#' # blindness
#' old <- options(
#'   covr.report_colors = c(covered = "#0072B2", missed = "#E69F00")
#' )
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

  # Create any directories as needed
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # Paths need to be absolute for save_html to work properly
  file <- file.path(
    normalizePath(dirname(file), mustWork = TRUE),
    basename(file)
  )

  ui <- report_page(html)

  htmltools::save_html(ui, file)
  viewer <- getOption("viewer", utils::browseURL)
  if (browse) {
    viewer(file)
  }
  invisible(file)
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
#' @return An [htmltools::tagList()], with the dependencies of the report
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
      )
    )
  ))
}

#' A coverage report for a specific file
#'
#' `file_report()` saves the coverage of one file as a standalone HTML file and
#' opens it. `file_report_html()` creates the same report as HTML that can be
#' included in a larger document, like [report_html()].
#'
#' @inheritParams report
#' @param file The file to report on, if `NULL`, use the first file in the
#'   coverage output.
#' @param out_file The output file
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

  htmltools::save_html(report_page(html), out_file)
  viewer <- getOption("viewer", utils::browseURL)
  if (browse) {
    viewer(out_file)
  }

  invisible(out_file)
}

#' @rdname file_report
#' @return `file_report_html()` returns an [htmltools::tagList()], with the
#'   dependencies of the report attached.
#' @export
file_report_html <- function(x = package_coverage(), file = NULL) {
  colors <- report_colors()
  check_report_installed()

  files <- display_name(x)

  if (is.null(file)) {
    file <- files[[1]]
  }
  stopifnot(length(file) == 1)

  x <- x[files %in% file]

  data <- to_report_data(x)

  percentage <- data$file_stats$Coverage

  htmltools::browsable(htmltools::tagList(
    report_head(),
    report_container(
      colors,
      report_header(paste0(file, " - ", percentage)),
      addHighlight(
        renderSourceTable(data$full, "")
      )
    )
  ))
}

check_report_installed <- function() {
  if (!requireNamespace("htmltools", quietly = TRUE)) {
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
      level <- if (number >= 90) {
        "high"
      } else if (number >= 75) {
        "mid"
      } else {
        "low"
      }
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

report_color_names <- c("covered", "missed", "partial")

# The colors from `getOption("covr.report_colors")`, as a 3 column matrix of
# red, green and blue values (0-255), with columns `covered` and `missed`, and
# `partial` if it is set. `partial` has no default; without it, the colors of
# files with partial coverage follow the defaults or `covered`.
report_colors <- function(colors = getOption("covr.report_colors")) {
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
    covr_abort(c(
      "{.code covr.report_colors} must be a named character vector.",
      i = "Use the names {.val covered}, {.val missed} and/or {.val partial}, e.g. {.code c(covered = \"#0072B2\", missed = \"#E69F00\")}."
    ))
  }

  res <- default_report_colors
  res[nms] <- colors
  res <- res[intersect(report_color_names, names(res))]

  valid <- vlapply(res, function(color) {
    tryCatch(is.matrix(grDevices::col2rgb(color)), error = function(e) FALSE)
  })
  if (!all(valid)) {
    invalid <- unname(res[!valid])
    covr_abort(c(
      "{.code covr.report_colors} must contain valid R colors.",
      x = "Can't find color{?s} {.val {invalid}}."
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

report_colors_css <- function(colors) {
  selector <- paste0(".covr-report.", report_colors_class(colors))
  rules <- vapply(
    c("covered", "missed"),
    function(type) {
      rgb <- colors[, type]
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
  htmltools::tags$style(htmltools::HTML(paste0(
    paste(rules, collapse = ""),
    coverage_tints_css(colors, selector)
  )))
}

# The element of a report, with the styles of its colors, which only apply to
# it, as the colors of other reports in the same document can differ
report_container <- function(colors, ...) {
  htmltools::div(
    class = paste("covr-report", report_colors_class(colors)),
    report_colors_css(colors),
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

  res$file_stats <- compute_file_stats(res$full)

  res$file_stats$File <- names(res$full)

  res$file_stats <- sort_file_stats(res$file_stats)

  res
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
      data.frame(
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
      "Coverage"
    )
  ]
}

renderSourceTable <- function(data, class = "covr-hidden") {
  htmltools::div(
    class = "covr-files",
    Map(
      function(lines, file) {
        htmltools::div(
          `data-file` = file,
          class = class,
          htmltools::tags$table(
            class = "table-condensed",
            htmltools::tags$tbody(
              lapply(seq_len(NROW(lines)), function(row_num) {
                coverage <- lines[row_num, "coverage"]

                cov_type <- NULL
                if (coverage == 0) {
                  cov_value <- "!"
                  cov_type <- "missed"
                } else if (coverage > 0) {
                  cov_value <- htmltools::HTML(paste0(
                    lines[row_num, "coverage"],
                    "<em>x</em>",
                    collapse = ""
                  ))
                  cov_type <- "covered"
                } else {
                  cov_type <- "never"
                  cov_value <- ""
                }
                htmltools::tags$tr(
                  class = cov_type,
                  htmltools::tags$td(class = "num", lines[row_num, "line"]),
                  htmltools::tags$td(class = "coverage", cov_value),
                  htmltools::tags$td(
                    class = "covr-source",
                    htmltools::pre(
                      class = "language-r",
                      lines[row_num, "source"]
                    )
                  )
                )
              })
            )
          )
        )
      },
      lines = data,
      file = names(data)
    ),
    # Only the code of this report, if a document includes several
    htmltools::tags$script(
      "(function(script) {
  var files = script ? script.parentNode : document;
  files.querySelectorAll('div.covr-files pre').forEach(function(block) {
    covrHljs.highlightBlock(block);
  });
})(document.currentScript);"
    )
  )
}

# covr's copy of highlight.js sets `covrHljs` rather than `hljs`, so it doesn't
# replace the version used by a document that includes a report. Its colors
# are in `report.css`.
addHighlight <- function(x = list()) {
  highlight <- htmltools::htmlDependency(
    "covr-highlight.js",
    "6.2",
    system.file(package = "covr", "www/shared/highlight.js"),
    script = "highlight.pack.js"
  )

  htmltools::attachDependencies(
    x,
    c(htmltools::htmlDependencies(x), list(highlight))
  )
}

addin_report <- function() {
  loadNamespace("rstudioapi")

  project <- rstudioapi::getActiveProject()

  pkg <- as_package(project %||% getwd())
  message("Calculating test coverage for ", pkg$package, "...")

  covr::report(covr::package_coverage(pkg$path))
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
