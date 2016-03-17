#' Display covr results using a shiny app
#'
#' The shiny app is designed to provide local information to coverage
#' information similar to the coveralls.io website.  However it does not and
#' will not track coverage over time.
#' @param x a coverage dataset
#' @param ... additional arguments passed to methods
#' @examples
#' \dontrun{
#' x <- package_coverage()
#' shine(x)
#' }
#' @export
shine <- function(x, ...) UseMethod("shine")

shine.default <- function(x, ...) {
  stop("shine must be called on a coverage object!", call. = FALSE)
}

#' @export
shine.coverages <- function(x, ...) {

  loadNamespace("shiny")

  data <- lapply(x, to_shiny_data)

  ui <- shiny::fluidPage(
    shiny::includeCSS(system.file("www/shiny.css", package = "covr")),
    shiny::column(2,
      shiny::radioButtons("type", label = shiny::h3("Coverage Type"),
        choices = setNames(names(data), to_title(names(data))))
    ),
    shiny::column(8,
      shiny::tabsetPanel(
        shiny::tabPanel("Files", DT::dataTableOutput(outputId = "file_table")),
        shiny::tabPanel("Source", addHighlight(shiny::tableOutput("source_table")))
        )
      ),
    title = paste(attr(x, "package")$package, "Coverage"))

  server <- function(input, output, session) {
    output$file_table <- DT::renderDataTable(
      data[[input$type]]$file_stats,
      escape = FALSE,
      options = list(searching = FALSE, dom = "t", paging = FALSE),
      rownames = FALSE,
      callback = DT::JS("table.on('click.dt', 'a', function() {
        Shiny.onInputChange('filename', $(this).text());
        $('ul.nav a[data-value=Source]').tab('show');
      });"))
    shiny::observe({
      if (!is.null(input$filename)) {
        output$source_table <- renderSourceTable(data[[input$type]]$full[[input$filename]])
      }
    })
  }

  shiny::runApp(list(ui = ui, server = server),
    launch.browser = getOption("viewer", utils::browseURL),
    quiet = TRUE
  )
}

#' @export
shine.coverage <- function(x, ...) {

  loadNamespace("shiny")

  data <- to_shiny_data(x)

  ui <- shiny::fluidPage(
    shiny::includeCSS(system.file("www/shiny.css", package = "covr")),
    shiny::column(8, offset = 2,
      shiny::tabsetPanel(
        shiny::tabPanel("Files", DT::dataTableOutput(outputId = "file_table")),
        shiny::tabPanel("Source", addHighlight(shiny::tableOutput("source_table")))
        )
      ),
    title = paste(attr(x, "package")$package, "Coverage"))

  server <- function(input, output, session) {
    output$file_table <- DT::renderDataTable(
      data$file_stats,
      escape = FALSE,
      options = list(searching = FALSE, dom = "t", paging = FALSE),
      rownames = FALSE,
      callback = DT::JS("table.on('click.dt', 'a', function() {
        Shiny.onInputChange('filename', $(this).text());
        $('ul.nav a[data-value=Source]').tab('show');
      });"))
    shiny::observe({
      if (!is.null(input$filename)) {
        output$source_table <- renderSourceTable(data$full[[input$filename]])
      }
    })
  }

  shiny::runApp(list(ui = ui, server = server),
    launch.browser = getOption("viewer", utils::browseURL),
    quiet = TRUE
  )
}

to_shiny_data <- function(x) {
  coverages <- per_line(x)

  res <- list()
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

  res$file_stats$Coverage <- add_color_box(res$file_stats$Coverage)

  res
}

compute_file_stats <- function(files) {
  do.call("rbind",
    lapply(files,
      function(file) {
        data.frame(
          Coverage = sprintf("%.2f", sum(file$coverage > 0) / sum(file$coverage != "") * 100),
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
  stats[order(as.numeric(stats$Coverage), -stats$Relevant),
        c("Coverage", "File", "Lines", "Relevant", "Covered", "Missed", "Hits / Line")]
}

add_link <- function(files) {
  vapply(files, character(1), FUN = function(file) {
           as.character(shiny::a(href = "#", file))
              })
}

add_color_box <- function(nums) {

  vapply(nums, character(1), FUN = function(num) {
    nnum <- as.numeric(num)
    if (nnum > 90) {
      as.character(shiny::div(class = "coverage-box coverage-high", num))
    } else if (nnum > 75) {
      as.character(shiny::div(class = "coverage-box coverage-medium", num))
    } else {
      as.character(shiny::div(class = "coverage-box coverage-low", num))
    }
  })
}

utils::globalVariables("func", "covr")

renderSourceTable <- function(expr, env = parent.frame()) {

  shiny::installExprFunction(expr, "func", env)

  shiny::markRenderFunction(shiny::tableOutput,
    function() {
      data <- func() # nolint

      if (is.null(data) || identical(data, data.frame())) {
        return("")
      }

      table <- as.character(shiny::tags$table(class = "table-condensed",
          shiny::tags$tbody(
            lapply(seq_len(NROW(data)),
              function(row_num) {
                coverage <- data[row_num, "coverage"]

                cov_type <- NULL
                if (coverage == 0) {
                  cov_value <- "!"
                  cov_type <- "missed"
                } else if (coverage > 0) {
                  cov_value <- shiny::HTML(paste0(data[row_num, "coverage"], "<em>x</em>", collapse = ""))
                  cov_type <- "covered"
                } else {
                  cov_type <- "never"
                  cov_value <- ""
                }
                shiny::tags$tr(class = cov_type,
                  shiny::tags$td(class = "num", data[row_num, "line"]),
                  shiny::tags$td(class = "col-sm-12", shiny::pre(class = "language-r", data[row_num, "source"])),
                  shiny::tags$td(class = "coverage", cov_value)
                  )
              })
            )
          )
        )

      paste(sep = "\n", table, "<script>
        $('#source_table pre').each(function(i, block) {
          hljs.highlightBlock(block);
          });
        </script>")
    })
}

addHighlight <- function(x = list()) {
  highlight <- htmltools::htmlDependency("highlight.js", "6.2",
                                         system.file(package = "shiny",
                                                     "www/shared/highlight"),
                                         script = "highlight.pack.js",
                                         stylesheet = "rstudio.css")

  htmltools::attachDependencies(x, c(htmltools::htmlDependencies(x), list(highlight)))
}
