ui <- shiny::fluidPage(
  shiny::numericInput("n", "n", 1),
  shiny::textOutput("out")
)

shiny::shinyApp(ui, function(input, output, session) {
  output$out <- shiny::renderText(double_it(input$n))
})
