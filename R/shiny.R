shine <- function(x) {
  coverages <- per_line(x)

  coverage_names <- names(coverages)

  if (!is.null(attr(x, "path"))) {
    coverage_names <- file.path(attr(x, "path"), coverage_names)
  }

  sources <- lapply(coverage_names, readLines)

  full <- Map(function(coverage, source){
                   length(coverage) <- length(source)
                   coverage[is.na(coverage)] <- ""
                   data.frame(line = seq_along(coverage), source = source, coverage = coverage, stringsAsFactors = FALSE)
  }, coverage = coverages, source = sources)

  file_stats <- do.call("rbind", lapply(full, function(file) {
                         data.frame(coverage = sprintf("%.2f", sum(file$coverage > 0) / sum(file$coverage != "") * 100),
                                    lines = NROW(file),
                                    relevant = sum(file$coverage != ""),
                                    covered = sum(file$coverage > 0),
                                    missed = sum(file$coverage == 0),
                                    `hits/line` = sprintf("%.0f", sum(as.numeric(file$coverage), na.rm = TRUE) / sum(file$coverage != "")), stringsAsFactors = FALSE, check.names = FALSE) }))

  file_stats$file <- add_link(names(full))

  file_stats <- file_stats[order(as.numeric(file_stats$coverage), -file_stats$relevant), c("coverage", "file", "lines", "relevant", "covered", "missed", "hits/line")]

  file_stats$coverage <- add_color_box(file_stats$coverage)

  runApp(list(ui = fluidPage(includeCSS("shiny2.css"),
                             includeScript("shiny.js"),
                             fluidRow(column(8, offset=2, dataTableOutput(outputId="file_table"))),
                             fluidRow(column(8, offset=2, addHighlight(tableOutput("source_table"))))
                                      ),
              server = function(input, output) {
                output$file_table <- renderDataTable(file_stats, escape = FALSE, options = list(searching = FALSE, dom = "t"), 
                                                     callback = "function(table) {
                                                     table.on('click.dt', 'a', function() {
                                                                $(this).toggleClass('selected');
                                                                Shiny.onInputChange('filename', $(this).text());
});
              }")
              shiny::observe({
                if (!is.null(input$filename)) {
                  output$source_table <- renderSourceTable(full[[input$filename]])
                }
              })
}))
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
  shiny::markRenderFunction(tableOutput, function() {
                       as.character(shiny::tags$table(class = "table-condensed",
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
                                                }
                                                )
                                         )))
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
