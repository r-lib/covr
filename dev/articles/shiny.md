# Coverage of Shiny apps

How you measure the test coverage of a Shiny app depends on where the
app’s code lives and how it is tested. Coverage is easiest to measure
when the app is part of an R package, because
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
instruments the whole package, in every R process that loads it.

## Apps in a package

Suppose a package defines its app with functions like these:

``` r

# R/app.R
app_ui <- function() {
  shiny::fluidPage(
    shiny::numericInput("n", "n", 1),
    shiny::textOutput("out")
  )
}

app_server <- function(input, output, session) {
  output$out <- shiny::renderText(input$n * 2)
}

run_app <- function() {
  shiny::shinyApp(app_ui(), app_server)
}
```

### Server tests with `testServer()`

`shiny::testServer()` runs the server function in the same R process as
the tests, so the code it runs counts towards the coverage like any
other test:

``` r

# tests/testthat/test-server.R
test_that("the server doubles n", {
  shiny::testServer(app_server, {
    session$setInputs(n = 2)
    expect_equal(output$out, "4")
  })
})
```

### Browser tests with shinytest2

A shinytest2 `AppDriver` runs the app in a separate R process. When that
process loads the package it loads the copy instrumented by covr, so the
code run by the app counts as well. Create the app with the package’s
functions, either by passing the app object to the driver:

``` r

# tests/testthat/test-app.R
test_that("the app doubles n", {
  app <- shinytest2::AppDriver$new(run_app())
  app$set_inputs(n = 2)
  expect_equal(app$get_value(output = "out"), "4")
  app$stop()
})
```

or with an `app.R` in the tests that calls them,
e.g. `mypkg::run_app()`, and `AppDriver$new(test_path("apps/myapp"))`.

The app process saves its coverage when it exits, so:

- Call `app$stop()` at the end of each test. It stops the app
  gracefully, and waits up to 20 seconds for it to exit when it is run
  by covr. The coverage of an app that is killed, or is still running
  when the tests finish, is lost and
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  warns (with class `covr_unsaved_trace`).

- `AppDriver$new()` skips the test on CRAN, which is the default unless
  the `NOT_CRAN` environment variable is `"true"`. The GitHub Actions
  set up by `r-lib/actions/setup-r` already set it; elsewhere set it
  before measuring the coverage:

  ``` r

  Sys.setenv(NOT_CRAN = "true")
  covr::package_coverage()
  ```

## Apps that are not in a package

covr can only instrument the code of an app that isn’t in a package when
it is run in the R session measuring the coverage. Use
[`file_coverage()`](https://covr.r-lib.org/dev/reference/file_coverage.md)
to source the app’s files and run tests that call its server function
with `testServer()`:

``` r

# app.R
library(shiny)

ui <- fluidPage(
  numericInput("n", "n", 1),
  textOutput("out")
)

server <- function(input, output, session) {
  output$out <- renderText(input$n * 3)
}

shinyApp(ui, server)
```

``` r

# tests/testthat/test-server.R
test_that("the server triples n", {
  testServer(server, {
    session$setInputs(n = 2)
    expect_equal(output$out, "6")
  })
})
```

``` r

library(testthat)
covr::file_coverage("app.R", "tests/testthat/test-server.R")
```

Add any other files that define the app’s functions, such as those in
its `R/` directory, to the `source_files`. Tests that run the app in
another R process, like shinytest2’s `AppDriver`, don’t count towards
the coverage of such an app. To measure them, move the app into a
package.
