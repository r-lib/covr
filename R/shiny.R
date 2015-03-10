#' Display covr results using a shiny app
#'
#' The shiny app is designed to provide local information to coverage
#' information similar to the coveralls.io website.  However it does not and
#' will not track coverage over time.
#' @param x a coverage dataset
#' @examples
#' \dontrun{
#' x <- package_coverage()
#' shine(x)
#' }
#' @export
shine <- function(x) {

  if (!inherits(x, "coverage")) {
    stop("shine must be called on a coverage object!", call. = FALSE)
  }
  coverages <- per_line(x)

  coverage_names <- names(coverages)

  if (!is.null(attr(x, "path"))) {
    coverage_names <- file.path(attr(x, "path"), coverage_names)
  }

  sources <- lapply(coverage_names, readLines)

  full <- Map(function(coverage, source){
                   length(coverage) <- length(source)
                   coverage[is.na(coverage)] <- ""
                   data.frame(line = seq_along(coverage),
                              source = source,
                              coverage = coverage,
                              stringsAsFactors = FALSE)

              },
              coverage = coverages,
              source = sources)

  file_stats <- compute_file_stats(full)

  file_stats$File <- add_link(names(full))

  file_stats <- sort_file_stats(file_stats)

  file_stats$Coverage <- add_color_box(file_stats$Coverage)

  ui <- shiny::fluidPage(shiny::includeCSS("shiny.css"),
        shiny::column(8, offset = 2,
          shiny::tabsetPanel(
            shiny::tabPanel("Files", shiny::dataTableOutput(outputId="file_table")),
            shiny::tabPanel("Source", addHighlight(shiny::tableOutput("source_table")))
            )
          )
        )

  server <- function(input, output, session) {
    output$file_table <- shiny::renderDataTable(
      file_stats,
      escape = FALSE,
      options = list(searching = FALSE, dom = "t"),
      callback = "function(table) {
      table.on('click.dt', 'a', function() {
        Shiny.onInputChange('filename', $(this).text());
        $('ul.nav a[data-value=Source]').tab('show');
      });
    }")
    shiny::observe({
      if (!is.null(input$filename)) {
        output$source_table <- renderSourceTable(full[[input$filename]])
      }
    })
  }

  shiny::runApp(list(ui = ui, server = server),
                launch.browser = getOption("viewer", utils::browseURL),
                quiet = TRUE
               )
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

renderSourceTable <- function(x) {
  shiny::markRenderFunction(shiny::tableOutput, function() {
    table <- as.character(shiny::tags$table(class = "table-condensed",
        shiny::tags$tbody(
          lapply(seq_len(NROW(x)),
            function(row_num) {
              coverage <- x[row_num, "coverage"]

              cov_type <- NULL
              if(coverage == 0) {
                cov_value <- "!"
                cov_type <- "missed"
              } else if(coverage > 0) {
                cov_value <- shiny::HTML(paste0(x[row_num, "coverage"], "<em>x</em>", collapse = ""))
                cov_type <- "covered"
              } else {
                cov_type <- "never"
                cov_value <- ""
              }
              shiny::tags$tr(class=cov_type,
                shiny::tags$td(class="num", x[row_num, "line"]),
                shiny::tags$td(class="col-sm-12", shiny::pre(class="language-r", x[row_num, "source"])),
                shiny::tags$td(class="coverage", cov_value)
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
