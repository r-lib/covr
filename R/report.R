#' Display covr results using a standalone report
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
  # Check the colors before running package_coverage()
  colors <- report_colors()

  # Create any directories as needed
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # Paths need to be absolute for save_html to work properly
  file <- file.path(
    normalizePath(dirname(file), mustWork = TRUE),
    basename(file)
  )

  if (
    !(requireNamespace("htmltools", quietly = TRUE) &&
      requireNamespace("DT", quietly = TRUE))
  ) {
    covr_abort(c(
      "{.fn report} requires the {.pkg DT} and {.pkg htmltools} packages.",
      i = 'Install them with {.code install.packages(c("DT", "htmltools"))}.'
    ))
  }

  data <- to_report_data(x)

  # Color the td cells by coverage amount, like codecov.io does. The colors
  # are CSS variables set by `report_colors_css()`, so they follow the theme.
  color_coverage_callback <- DT::JS(
    'function(td, cellData, rowData, row, col) {
  var percent = cellData.replace("%", "");
  var level = percent >= 90 ? "high" : percent >= 75 ? "mid" : "low";
  $(td).css("background", "linear-gradient(90deg, var(--covr-bar-" + level + ") " + cellData + ", transparent " + cellData + ")");
}
'
  )

  # Open a new file in the source tab and switch to it, starting at the top of
  # the file
  file_choice_callback <- DT::JS(
    "table.on('click.dt', 'a', function(e) {
  e.preventDefault();
  files = $('div#files div');
  files.not('div.hidden').addClass('hidden');
  id = $(this).text();
  files.filter('div[id=\\'' + id + '\\']').removeClass('hidden');
  $('ul.nav a[data-value=Source]').removeData('scroll').text(id).tab('show');
});"
  )

  package_name <- attr(x, "package")$package
  percentage <- sprintf("%02.2f%%", data$overall)

  table <- DT::datatable(
    data$file_stats,
    escape = FALSE,
    fillContainer = FALSE,
    options = list(
      searching = FALSE,
      dom = "t",
      paging = FALSE,
      columnDefs = list(
        list(targets = 6, createdCell = color_coverage_callback)
      )
    ),
    rownames = FALSE,
    class = "row-border",
    callback = file_choice_callback
  )
  table$sizingPolicy$defaultWidth <- "100%"
  table$sizingPolicy$defaultHeight <- NULL

  ui <- fluid_page(
    report_head(colors),
    htmltools::includeScript(system.file("www/report.js", package = "covr")),
    column(
      8,
      offset = 2,
      size = "md",
      report_header(paste0(package_name, " coverage - ", percentage)),
      tabset_panel(
        tab_panel("Files", table),
        tab_panel("Source", addHighlight(renderSourceTable(data$full)))
      )
    )
  )

  htmltools::save_html(ui, file)
  viewer <- getOption("viewer", utils::browseURL)
  if (browse) {
    viewer(file)
  }
  invisible(file)
}

#' A coverage report for a specific file
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
  loadNamespace("htmltools")
  loadNamespace("DT")

  colors <- report_colors()

  files <- display_name(x)

  if (is.null(file)) {
    file <- files[[1]]
  }
  stopifnot(length(file) == 1)

  x <- x[files %in% file]

  data <- to_report_data(x)

  percentage <- data$file_stats$Coverage

  ui <- fluid_page(
    js = FALSE,
    report_head(colors),
    column(
      8,
      offset = 2,
      size = "md",
      report_header(paste0(file, " - ", percentage)),
      addHighlight(
        renderSourceTable(data$full, "")
      )
    )
  )

  htmltools::save_html(ui, out_file)
  viewer <- getOption("viewer", utils::browseURL)
  if (browse) {
    viewer(out_file)
  }

  invisible(out_file)
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
    stop(
      "`covr.report_colors` must be a named character vector with elements ",
      "`covered`, `missed` and/or `partial`, e.g. ",
      'c(covered = "#0072B2", missed = "#E69F00").',
      call. = FALSE
    )
  }

  res <- default_report_colors
  res[nms] <- colors
  res <- res[intersect(report_color_names, names(res))]

  rgb <- tryCatch(
    grDevices::col2rgb(res),
    error = function(e) {
      stop(
        "`covr.report_colors` must contain valid R colors: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
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
coverage_tints_css <- function(colors) {
  vars <- function(tints) {
    paste0("  --covr-bar-", names(tints), ":", tints, ";\n", collapse = "")
  }
  paste0(
    ":root{\n",
    vars(coverage_tints(colors)),
    "}\n",
    "html.dark{\n",
    vars(coverage_tints(colors, dark = TRUE)),
    "}\n"
  )
}

report_colors_css <- function(colors) {
  rules <- vapply(
    c("covered", "missed"),
    function(type) {
      rgb <- colors[, type]
      hex <- rgb_hex(rgb)
      paste0(
        "table tr.",
        type,
        " td{\n  background-color:",
        rgb_alpha(rgb, 0.3),
        "\n}\n",
        "table tr:hover.",
        type,
        " .num{\n  background-color:",
        rgb_alpha(rgb, 0.7),
        "\n}\n",
        "table tr.",
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
    coverage_tints_css(colors)
  )))
}

# The styles and the script that picks the light or dark theme, which is in
# the <head> so the page is never shown in the wrong theme
report_head <- function(colors) {
  htmltools::tagList(
    htmltools::includeCSS(system.file("www/report.css", package = "covr")),
    report_colors_css(colors),
    htmltools::tags$head(
      htmltools::includeScript(system.file("www/theme.js", package = "covr"))
    )
  )
}

report_header <- function(title) {
  htmltools::div(
    class = "covr-header",
    htmltools::h2(title),
    htmltools::tags$button(
      type = "button",
      class = "btn btn-default btn-sm covr-theme-toggle",
      `aria-pressed` = "false",
      `aria-label` = "Dark mode",
      title = "Toggle dark mode",
      htmltools::HTML(theme_icons)
    )
  )
}

# The moon is shown in the light theme and the sun in the dark one
theme_icons <- paste0(
  '<svg class="covr-icon-moon" aria-hidden="true" width="16" height="16" ',
  'viewBox="0 0 16 16"><mask id="covr-moon-cut"><rect width="16" height="16" ',
  'fill="white"/><circle cx="11.5" cy="4.5" r="4.5" fill="black"/></mask>',
  '<circle cx="8" cy="8" r="6.5" fill="currentColor" ',
  'mask="url(#covr-moon-cut)"/></svg>',
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

  res$file_stats$File <- add_link(names(res$full))

  res$file_stats <- sort_file_stats(res$file_stats)

  res$file_stats$Coverage <- res$file_stats$Coverage

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

add_link <- function(files) {
  vcapply(files, function(file) {
    as.character(htmltools::a(href = "#", file))
  })
}

renderSourceTable <- function(data, class = "hidden") {
  htmltools::div(
    id = "files",
    Map(
      function(lines, file) {
        htmltools::div(
          id = file,
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
                    class = "col-sm-12",
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
    htmltools::tags$script(
      "document.querySelectorAll('div#files pre').forEach(function(block) {
  hljs.highlightBlock(block);
});"
    )
  )
}

addHighlight <- function(x = list()) {
  highlight <- htmltools::htmlDependency(
    "highlight.js",
    "6.2",
    system.file(package = "covr", "www/shared/highlight.js"),
    script = "highlight.pack.js",
    stylesheet = "rstudio.css"
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

# These are all adapted from functions in shiny

column <- function(width, ..., offset = 0, size = c("xs", "sm", "md", "lg")) {
  size <- match.arg(size)

  col_class <- paste0("col-", size, "-", width)
  if (offset > 0) {
    col_class <- paste0(col_class, " ", "col-", size, "-offset-", offset)
  }
  htmltools::div(class = col_class, ...)
}

tab_panel <- function(title, ..., value = title) {
  htmltools::div(class = "tab-pane", title = title, `data-value` = value, ...)
}

# `js = FALSE` leaves out Bootstrap's JavaScript, which needs jQuery and is
# only used for the tabs in `report()`
fluid_page <- function(..., js = TRUE) {
  bootstrap_page(
    htmltools::div(class = "container-fluid", ...),
    js = js
  )
}

bootstrap_page <- function(..., js = TRUE) {
  htmltools::attachDependencies(
    htmltools::tagList(list(...)),
    html_dependency_bootstrap(js = js)
  )
}

# from htmldeps::html_dependency_bootstrap (not yet on CRAN)
html_dependency_bootstrap <- function(js = TRUE) {
  script <- c("shim/html5shiv.min.js", "shim/respond.min.js")
  if (js) {
    script <- c("js/bootstrap.min.js", script)
  }
  htmltools::htmlDependency(
    name = "bootstrap",
    version = "3.4.1",
    src = system.file(file = "www/shared/bootstrap", package = "covr"),
    meta = list(viewport = "width=device-width, initial-scale=1"),
    script = script,
    stylesheet = c("css/bootstrap.min.css", "css/bootstrap-theme.min.css")
  )
}

tabset_panel <- function(...) {
  tabset <- build_tabset(list(...))
  htmltools::div(class = "tabbable", tabset$nav_list, tabset$content)
}

build_tabset <- function(tabs) {
  tabset_id <- "covr"
  tabs <- lapply(
    seq_len(length(tabs)),
    build_tab_item,
    tabs = tabs,
    tabset_id = tabset_id
  )
  list(
    nav_list = ul(
      class = "nav nav-tabs",
      `data-tabsetid` = tabset_id,
      lapply(tabs, "[[", 1)
    ),
    content = htmltools::div(
      class = "tab-content",
      `data-tabsetid` = tabset_id,
      lapply(tabs, "[[", 2)
    )
  )
}

build_tab_item <- function(i, tabs, tabset_id) {
  div_tag <- tabs[[i]]
  tab_id <- paste("tab", tabset_id, i, sep = "-")
  li_tag <- li(
    htmltools::a(
      href = paste0("#", tab_id),
      `data-toggle` = "tab",
      `data-value` = div_tag$attribs$`data-value`,
      div_tag$attribs$title
    )
  )
  if (i == 1) {
    li_tag$attribs$class <- "active"
    div_tag$attribs$class <- paste(div_tag$attribs$class, "active")
  }
  div_tag$attribs$id <- tab_id

  list(li_tag = li_tag, div_tag = div_tag)
}

li <- function(...) htmltools::tag("li", list(...))
ul <- function(...) htmltools::tag("ul", list(...))
