test_that("shiny_app_coverage() requires shiny and an existing app directory", {
  local_mocked_bindings(is_installed = function(pkg) FALSE)
  expect_snapshot(shiny_app_coverage(test_path("TestShinyApp")), error = TRUE)

  local_mocked_bindings(is_installed = function(pkg) TRUE)
  missing <- file.path(normalize_path(withr::local_tempdir()), "app")
  expect_snapshot(
    shiny_app_coverage(missing),
    error = TRUE,
    transform = function(x) sub(missing, "<app>", x, fixed = TRUE)
  )
})

test_that("shiny_app_coverage() works without the parallel fix", {
  skip_if_not_installed("shiny")

  local_mocked_bindings(should_enable_parallel_mcexit_fix = function(...) FALSE)
  cov <- shiny_app_coverage(
    test_path("TestShinyApp"),
    shiny::testServer(test_path("TestShinyApp"), session$setInputs(n = 2))
  )

  expect_equal(as.data.frame(cov)$value, c(1, 0, 1))
})

test_that("start_shiny_app_tracing() instruments the app's functions when shiny is loaded", {
  skip_on_os("windows")
  skip_if_not_installed("shiny")
  local_shiny_tracing_state()

  app_dir <- normalize_path(test_path("TestShinyApp"))
  trace_dir <- withr::local_tempdir()
  attach_env <- new.env()
  registered <- character()
  local_mocked_bindings(
    register_trace = function(ns, directory) {
      registered <<- c(registered, directory)
    }
  )

  start_shiny_app_tracing(app_dir, trace_dir, attach_env)
  expect_s4_class(shiny:::sourceUTF8, "functionWithTrace")

  outside <- withr::local_tempfile(fileext = ".R")
  writeLines("x <- function() 1", outside)
  env <- new.env()
  shiny:::sourceUTF8(outside, env)
  expect_equal(length(the$shiny_replacements), 0)

  attach_env$registerShinyDebugHook(list(name = "x", where = env))
  expect_equal(length(the$shiny_replacements), 0)
  expect_equal(registered, character())

  env <- new.env()
  shiny:::sourceUTF8(file.path(app_dir, "R", "helpers.R"), env)
  expect_equal(registered, trace_dir)
  expect_equal(length(the$shiny_replacements), 2)
  expect_identical(the$shiny_trace_registered, TRUE)
})

test_that("start_shiny_app_tracing() waits for shiny to load", {
  skip_if_not_installed("shiny")
  local_shiny_tracing_state()
  local_mocked_bindings(shiny_loaded = function() FALSE)

  original <- shiny:::sourceUTF8
  attach_env <- new.env()
  start_shiny_app_tracing("app", "trace", attach_env)
  expect_type(attach_env$registerShinyDebugHook, "closure")
  expect_identical(shiny:::sourceUTF8, original)

  hooks <- getHook(packageEvent("shiny", "onLoad"))
  hooks[[length(hooks)]]("shiny", .libPaths()[1])
  expect_s4_class(shiny:::sourceUTF8, "functionWithTrace")
})

test_that("trace_shiny_source() warns if shiny's sourceUTF8() has changed", {
  skip_if_not_installed("shiny")

  expect_snapshot(restore <- trace_shiny_source(function(path) NULL))
  expect_null(restore())
})

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

test_that("shiny_app_coverage() works with apps whose functions need parse data (#761)", {
  skip_if_not_installed("shiny")

  app_dir <- withr::local_tempdir()
  app_coverage <- function(describe) {
    writeLines(
      c(
        "library(shiny)",
        'ui <- fluidPage(numericInput("n", "n", 1), textOutput("o"))',
        "describe <- function(n) {",
        describe,
        "}",
        "server <- function(input, output, session) {",
        "  output$o <- renderText(describe(input$n))",
        "}",
        "shinyApp(ui, server)"
      ),
      file.path(app_dir, "app.R")
    )
    shiny_app_coverage(
      app_dir,
      shiny::testServer(app_dir, session$setInputs(n = 2))
    )
  }

  cov <- app_coverage('  if (n < 0) "negative" else "positive"')
  df <- as.data.frame(cov)
  expect_equal(df$functions, c("describe", "describe", "describe", "server"))
  expect_equal(df$value, c(1, 0, 1, 1))
  expect_length(per_line(cov)[["app.R"]]$coverage, 9)

  # Parse data of the app's files isn't reused after the files change
  cov <- app_coverage('  if (n < 0) "a negative number" else "positive"')
  df <- as.data.frame(cov)
  expect_equal(df$first_column, c(7, 14, 39, 3))
  expect_equal(df$value, c(1, 0, 1, 1))
})

test_that("shiny_app_coverage() sources app files without Ark's breakpoint annotations", {
  skip_if_not_installed("shiny")
  skip_if(is.null(asNamespace("shiny")$maybeAnnotateSourceForArk))

  # Like Positron's Ark with a breakpoint on line 4
  annotate <- function(file, lines) {
    uri <- sprintf('#line %%d "file://%s"', normalize_path(file))
    c(
      "base::list({",
      sprintf(uri, 1),
      lines[1:3],
      "browser()",
      sprintf(uri, 4),
      lines[-(1:3)],
      "})[[1]]"
    )
  }
  original <- asNamespace("shiny")$maybeAnnotateSourceForArk
  replace_binding("shiny", "maybeAnnotateSourceForArk", annotate)
  withr::defer(replace_binding("shiny", "maybeAnnotateSourceForArk", original))

  app_dir <- withr::local_tempdir()
  writeLines(
    c(
      "library(shiny)",
      'ui <- fluidPage(numericInput("n", "n", 1), textOutput("o"))',
      "describe <- function(n) {",
      '  if (n < 0) "negative" else "positive"',
      "}",
      "server <- function(input, output, session) {",
      "  output$o <- renderText(describe(input$n))",
      "}",
      "shinyApp(ui, server)"
    ),
    file.path(app_dir, "app.R")
  )
  cov <- shiny_app_coverage(
    app_dir,
    shiny::testServer(app_dir, session$setInputs(n = 2))
  )

  df <- as.data.frame(cov)
  expect_equal(df$filename, rep("app.R", 4))
  expect_equal(df$first_column, c(7, 14, 30, 3))
  expect_equal(df$value, c(1, 0, 1, 1))
  expect_identical(asNamespace("shiny")$maybeAnnotateSourceForArk, annotate)
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

  expect_snapshot(
    shiny_app_coverage(test_path("TestShinyApp"), stop("boom", call. = FALSE)),
    error = TRUE
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

test_that("shiny_app_coverage() includes apps first loaded by processes forked by other R processes", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_not_installed("shiny")
  skip_if_not_installed("callr")

  app_dir <- normalizePath(test_path("TestShinyApp"))
  expect_no_warning(
    cov <- shiny_app_coverage(
      app_dir,
      callr::r(
        function(app_dir) {
          parallel::mccollect(parallel::mcparallel(
            shiny::testServer(app_dir, session$setInputs(n = 2))
          ))
        },
        list(app_dir)
      )
    )
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
