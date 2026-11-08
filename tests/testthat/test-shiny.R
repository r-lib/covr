test_that("shiny_app_coverage() instruments the app's files in this process", {
  skip_if_not_installed("shiny")

  cov <- shiny_app_coverage(
    test_path("TestShinyApp"),
    shiny::testServer(test_path("TestShinyApp"), {
      session$setInputs(n = 2)
      expect_equal(output$out, "4")
    })
  )

  df <- as.data.frame(cov)
  expect_equal(df$filename, c("R/helpers.R", "R/helpers.R"))
  expect_equal(df$functions, c("double_it", "never_called"))
  expect_equal(df$value, c(1, 0))
  expect_equal(class(shiny:::sourceUTF8), "function")
})

test_that("shiny_app_coverage() includes the server function run by other R processes", {
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("callr")

  app_dir <- normalizePath(test_path("TestShinyApp"))
  cov <- shiny_app_coverage(
    app_dir,
    callr::r(
      function(app_dir) {
        # Like a Shiny session starting the server function of the app
        app <- shiny::shinyAppDir(app_dir)
        env <- new.env()
        env$server <- app$serverFuncSource()
        shiny:::registerDebugHook("server", env, "Server Function")
        shiny::testServer(env$server, session$setInputs(n = 2))
      },
      list(app_dir)
    )
  )

  df <- as.data.frame(cov)
  expect_equal(df$filename, c("R/helpers.R", "R/helpers.R", "app.R"))
  expect_equal(df$first_line, c(2, 6, 7))
  expect_equal(df$value, c(1, 0, 1))
})

test_that("shiny_app_coverage() warns about app processes that didn't save their coverage", {
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("callr")

  app_dir <- normalizePath(test_path("TestShinyApp"))
  loaded <- withr::local_tempfile()
  expect_warning(
    shiny_app_coverage(app_dir, {
      p <- callr::r_bg(
        function(app_dir, loaded) {
          shiny::shinyAppDir(app_dir)$serverFuncSource()
          file.create(loaded)
          Sys.sleep(60)
        },
        list(app_dir, loaded)
      )
      deadline <- Sys.time() + 30
      while (!file.exists(loaded) && Sys.time() < deadline) {
        Sys.sleep(0.1)
      }
      p$kill()
    }),
    class = "covr_unsaved_trace"
  )
})
