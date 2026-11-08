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
  expect_equal(df$filename, c("R/helpers.R", "R/helpers.R", "app.R"))
  expect_equal(df$functions, c("double_it", "never_called", "server"))
  expect_equal(df$value, c(1, 0, 1))
  expect_equal(class(shiny:::sourceUTF8), "function")
})

test_that("shiny_app_coverage() restores a sourceUTF8() traced before, also on error", {
  skip_if_not_installed("shiny")

  suppressMessages(trace(
    "sourceUTF8",
    quote(NULL),
    where = asNamespace("shiny"),
    print = FALSE
  ))
  withr::defer(suppressMessages(untrace(
    "sourceUTF8",
    where = asNamespace("shiny")
  )))
  traced <- shiny:::sourceUTF8

  expect_error(
    shiny_app_coverage(test_path("TestShinyApp"), stop("boom")),
    "boom"
  )
  expect_identical(shiny:::sourceUTF8, traced)
})

test_that("shiny_app_coverage() includes functions run by forked processes", {
  skip_on_os("windows")
  skip_if_not_installed("shiny")

  cov <- shiny_app_coverage(
    test_path("TestShinyApp"),
    parallel::mccollect(parallel::mcparallel(
      shiny::testServer(test_path("TestShinyApp"), session$setInputs(n = 2))
    ))
  )

  df <- as.data.frame(cov)
  expect_equal(df$functions, c("double_it", "never_called", "server"))
  expect_equal(df$value, c(1, 0, 1))
})

test_that("shiny_app_coverage() instruments functions passed to Shiny's debug hook in other R processes", {
  skip_on_cran()
  skip_if_not_installed("shiny")
  skip_if_not_installed("callr")

  app_dir <- normalizePath(test_path("TestShinyApp"))
  cov <- shiny_app_coverage(
    app_dir,
    callr::r(
      function(app_dir) {
        # Shiny calls the hook with the server function when a session starts
        env <- new.env()
        sys.source(
          file.path(app_dir, "R", "helpers.R"),
          envir = env,
          keep.source = TRUE
        )
        shiny:::registerDebugHook("double_it", env, "double_it")
        env$double_it(1)
      },
      list(app_dir)
    )
  )

  df <- as.data.frame(cov)
  expect_equal(df$functions, "double_it")
  expect_equal(df$value, 1)
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
