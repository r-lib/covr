#' Display covr results using a standalone report
#'
#' @param x a coverage dataset, defaults to running `package_coverage()`.
#' @param file The report filename.
#' @param browse whether to open a browser to view the report.
#' @examples
#' \dontrun{
#' x <- package_coverage()
#' report(x)
#' }
#' @export
# This function was originally a shiny application, but has been converted into
# a normal static document. Hence the shiny calls / dependency despite not
# actually using shiny.
report <- function(x = package_coverage(),
  file = file.path(tempdir(), paste0(get_package_name(x), "-report.html")),
  browse = interactive()) {

  # Create any directories as needed
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # Paths need to be absolute for save_html to work properly
  file <- file.path(normalizePath(dirname(file), mustWork = TRUE), basename(file))

  loadNamespace("shiny")
  loadNamespace("DT")

  data <- to_shiny_data(x)

  # Color the td cells by coverage amount, like codecov.io does
  color_coverage_callback <- DT::JS(
'function(td, cellData, rowData, row, col) {
console.log(cellData);
  var percent = cellData.replace("%", "");
  if (percent > 90) {
    var grad = "linear-gradient(90deg, #edfde7 " + cellData + ", white " + cellData + ")";
  } else if (percent > 75) {
    var grad = "linear-gradient(90deg, #f9ffe5 " + cellData + ", white " + cellData + ")";
  } else {
    var grad = "linear-gradient(90deg, #fcece9 " + cellData + ", white " + cellData + ")";
  }
  $(td).css("background", grad);
}
')

  # Open a new file in the source tab and switch to it
  file_choice_callback <- DT::JS(
"table.on('click.dt', 'a', function() {
  files = $('div#files div');
  files.not('div.hidden').addClass('hidden');
  id = $(this).text();
  files.filter('div[id=\\'' + id + '\\']').removeClass('hidden');
  $('ul.nav a[data-value=Source]').text(id).tab('show');
});")

  package_name <- attr(x, "package")$package
  percentage <- sprintf("%02.2f%%", data$overall)

  ui <- shiny::fluidPage(
    shiny::includeCSS(system.file("www/shiny.css", package = "covr")),
    column(8, offset = 2, size = "md",
      shiny::HTML(paste0("<h2>", package_name, " coverage - ", percentage, "</h2>")),
      shiny::tabsetPanel(
        shiny::tabPanel("Files",
          DT::datatable(
            data$file_stats,
            escape = FALSE,
            options = list(
              searching = FALSE,
              dom = "t",
              paging = FALSE,
              columnDefs = list(
                list(targets = 6, createdCell = color_coverage_callback))),
            rownames = FALSE,
            class = "row-border",
            callback = file_choice_callback
          )
        ),
        shiny::tabPanel("Source", addHighlight(renderSourceTable(data$full)))
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
file_report <- function(x = package_coverage(), file = NULL, out_file = file.path(tempdir(), paste0(get_package_name(x), "-file-report.html")), browse = interactive()) {
  loadNamespace("shiny")
  loadNamespace("DT")

  files <- display_name(x)

  if (is.null(file)) {
    file <- files[[1]]
  }
  stopifnot(length(file) == 1)

  x <- x[files %in% file]

  data <- to_shiny_data(x)

  percentage <- data$file_stats$Coverage

  ui <- shiny::fluidPage(
    shiny::includeCSS(system.file("www/shiny.css", package = "covr")),
    column(8, offset = 2, size = "md",
      shiny::HTML(paste0("<h2>", file, " - ", percentage, "</h2>")),
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

to_shiny_data <- function(x) {
  coverages <- per_line(x)

  res <- list()
  res$overall <- percent_coverage(x)
  res$full <- lapply(coverages,
    function(coverage) {
      lines <- coverage$file$file_lines
      values <- coverage$coverage
      values[is.na(values)] <- ""
      data.frame(
        line = seq_along(lines),
        source = lines,
        coverage = values,
        stringsAsFactors = FALSE)
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
  do.call("rbind",
    lapply(files,
      function(file) {
        data.frame(
          Coverage = sprintf("%.2f%%", sum(file$coverage > 0) / sum(file$coverage != "") * 100),
          Lines = NROW(file),
          Relevant = sum(file$coverage != ""),
          Covered = sum(file$coverage > 0),
          Missed = sum(file$coverage == 0),
          `Hits / Line` = sprintf("%.0f", sum(as.numeric(file$coverage), na.rm = TRUE) / sum(file$coverage != "")),
          stringsAsFactors = FALSE,
          check.names = FALSE)
      }
    )
  )
}

sort_file_stats <- function(stats) {
  stats[order(as.numeric(sub("%", "", stats$Coverage)), -stats$Relevant),
        c("File", "Lines", "Relevant", "Covered", "Missed", "Hits / Line", "Coverage")]
}

add_link <- function(files) {
  vcapply(files, function(file) { as.character(shiny::a(href = "#", file)) })
}

renderSourceTable <- function(data, class = "hidden") {

  shiny::tags$div(id = "files",
    Map(function(lines, file) {
      shiny::tags$div(id = file, class=class,
        shiny::tags$table(class = "table-condensed",
          shiny::tags$tbody(
            lapply(seq_len(NROW(lines)),
              function(row_num) {
                coverage <- lines[row_num, "coverage"]

                cov_type <- NULL
                if (coverage == 0) {
                  cov_value <- "!"
                  cov_type <- "missed"
                } else if (coverage > 0) {
                  cov_value <- shiny::HTML(paste0(lines[row_num, "coverage"], "<em>x</em>", collapse = ""))
                  cov_type <- "covered"
                } else {
                  cov_type <- "never"
                  cov_value <- ""
                }
                shiny::tags$tr(class = cov_type,
                  shiny::tags$td(class = "num", lines[row_num, "line"]),
                  shiny::tags$td(class = "coverage", cov_value),
                  shiny::tags$td(class = "col-sm-12", shiny::pre(class = "language-r", lines[row_num, "source"]))
                  )
              })
            )
          ))
    }, lines = data, file = names(data)),
  shiny::tags$script(
    "$('div#files pre').each(function(i, block) {
    hljs.highlightBlock(block);
});"))
}

addHighlight <- function(x = list()) {
  highlight <- htmltools::htmlDependency("highlight.js", "6.2",
                                         system.file(package = "shiny",
                                                     "www/shared/highlight"),
                                         script = "highlight.pack.js",
                                         stylesheet = "rstudio.css")

  htmltools::attachDependencies(x, c(htmltools::htmlDependencies(x), list(highlight)))
}

addin_report <- function() {
  loadNamespace("rstudioapi")

  project <- rstudioapi::getActiveProject()

  covr::report(covr::package_coverage(project %||% getwd()))
}

column <- function(width, ..., offset = 0, size = c("xs", "sm", "md", "lg")) {
  size <- match.arg(size)

  col_class <- paste0("col-", size, "-", width)
  if (offset > 0) {
    col_class <- paste0(col_class, " ", "col-", size, "-offset-", offset)
  }
  shiny::div(class = col_class, ...)
}
