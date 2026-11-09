# shiny_app_coverage() requires shiny and an existing app directory

    Code
      shiny_app_coverage(test_path("TestShinyApp"))
    Condition
      Error:
      ! shiny must be installed to measure Shiny app coverage.

---

    Code
      shiny_app_coverage(missing)
    Condition
      Error:
      ! Can't find the Shiny app directory '<app>'.

# trace_shiny_source() warns if shiny's sourceUTF8() has changed

    Code
      restore <- trace_shiny_source(function(path) NULL)
    Condition
      Warning:
      Can't instrument the files of the Shiny app.
      i This version of shiny is not supported by covr.

