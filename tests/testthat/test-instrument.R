test_that("package_coverage() loads an instrumented and byte-compiled package", {
  skip_on_cran()
  withr::local_envvar(COVR_INSTALL_COMPILE = NA)
  withr::local_options(covr.install_compile = NULL)
  log <- withr::local_tempfile()
  cov <- withr::with_envvar(
    c(TESTINSTRUMENT_LOG = log),
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        "stopifnot(TestInstrument::is_compiled(TestInstrument::f))",
        "stopifnot(TestInstrument::is_compiled(TestInstrument::is_compiled))",
        "TestInstrument::f(1)",
        "TestInstrument::f(2)"
      )
    )
  )

  # `R CMD INSTALL` loads the package to test it and the process that runs the
  # code loads it, but the process that instruments it doesn't run `.onLoad()`.
  expect_length(readLines(log), 2L)

  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 11L], 2)
  expect_equal(df$value[df$first_line == 13L], 0)
})

test_that("package_coverage() instruments functions that .onLoad() creates", {
  skip_on_cran()
  log <- withr::local_tempfile()
  cov <- withr::with_envvar(
    c(TESTINSTRUMENT_LOG = log),
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        "stopifnot(covr:::is_traced(TestInstrument:::made))",
        "stopifnot(TestInstrument:::made(1) == 2)",
        "covr:::sync_counts()",
        "keys <- grep('^<text>', ls(covr:::.counters), value = TRUE)",
        "stopifnot(length(keys) > 0, all(vapply(keys, function(k) covr:::.counters[[k]]$value, numeric(1)) == 1))",
        "TestInstrument::f(1)"
      )
    )
  )

  expect_length(readLines(log), 2L)
  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 11L], 1)
  expect_equal(df$value[df$first_line == 13L], 0)
})

test_that("instrument_package() returns the file with the counters", {
  skip_on_cran()
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)

  file <- instrument_package(pkg, lib)
  expect_equal(file, file.path(lib, "TestInstrument", "R", "covr_counters.rds"))
  counters <- readRDS(file)
  expect_gt(length(ls(counters)), 0L)
  # `expect_all_equal()` needs testthat 3.3.0, which isn't on R 4.0
  values <- unname(vapply(as.list(counters), function(x) x$value, numeric(1)))
  expect_equal(values, rep(0, length(values)))
})

test_that("instrument_package() leaves packages with functions in sysdata.rda", {
  skip_on_cran()
  src <- withr::local_tempdir()
  file.copy(test_path("TestInstrument"), src, recursive = TRUE)
  g <- function(x) x
  save(g, file = file.path(src, "TestInstrument", "R", "sysdata.rda"))
  lib <- withr::local_tempdir()
  pkg <- as_package(file.path(src, "TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)

  expect_no_warning(file <- instrument_package(pkg, lib))
  expect_null(file)
})

test_that("instrument_package() warns if the package can't be instrumented", {
  skip_on_cran()
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)
  unlink(file.path(lib, "TestInstrument", "Meta", "package.rds"))

  expect_warning(
    file <- instrument_package(pkg, lib),
    class = "covr_instrument_failed"
  )
  expect_null(file)
})

test_that("package_coverage() instruments the package when it is loaded if it can't ahead of time", {
  skip_on_cran()
  local_mocked_bindings(instrument_package = function(...) NULL)
  cov <- package_coverage(
    test_path("TestInstrument"),
    type = "none",
    code = "TestInstrument::f(1)"
  )

  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 11L], 1)
  expect_equal(df$value[df$first_line == 13L], 0)
})

test_that("restore_counters() keeps the counts of a namespace that is restored again", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  ns <- new.env()
  file <- withr::local_tempfile()
  counters <- new.env()
  counters[["a.R:1:1"]] <- list(value = 0, functions = "a")
  saveRDS(counters, file)

  restore_counters(ns, file)
  .counters[["a.R:1:1"]]$value <- 3
  restore_counters(ns, file)
  expect_equal(.counters[["a.R:1:1"]]$value, 3)

  restore_counters(new.env(), file)
  expect_equal(.counters[["a.R:1:1"]]$value, 0)
})

test_that("restore_counters() instruments a package that is loaded again", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  file <- withr::local_tempfile()
  counters <- new.env()
  counters[["a.R:1:1"]] <- list(value = 0, functions = "a")
  saveRDS(counters, file)
  restore_counters(new.env(), file)

  src <- srcfilecopy("b.R", c("f <- function(x) {", "  x + 1", "}"))
  exprs <- parse(text = src$lines, keep.source = TRUE, srcfile = src)
  ns <- new.env()
  eval(exprs[[1]], ns)
  restore_counters(ns, file)

  expect_true(is_traced(ns$f))
  expect_contains(ls(.counters), "a.R:1:1")
  expect_gt(length(grep("^b.R", ls(.counters))), 0L)
})

test_that("package_byte_compile() reads the ByteCompile field like R CMD INSTALL", {
  lib <- withr::local_tempdir()
  dir.create(file.path(lib, "p", "Meta"), recursive = TRUE)
  field <- function(value) {
    desc <- c(Package = "p", ByteCompile = value)
    saveRDS(
      list(DESCRIPTION = desc[!is.na(desc)]),
      file.path(lib, "p", "Meta", "package.rds")
    )
    package_byte_compile("p", lib)
  }
  expect_true(field("yes"))
  expect_true(field("TRUE"))
  expect_false(field("no"))
  expect_false(field("false"))
  expect_equal(field(NA_character_), NA)
})

test_that("covr.install_compile = FALSE leaves the stored functions uncompiled", {
  skip_on_cran()
  withr::local_envvar(COVR_INSTALL_COMPILE = NA)
  withr::local_options(covr.install_compile = NULL)
  run <- function(is_compiled) {
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        sprintf(
          "stopifnot(%s(TestInstrument::is_compiled(TestInstrument::f)))",
          if (is_compiled) "" else "!"
        ),
        "TestInstrument::f(1)",
        "TestInstrument::f(2)"
      )
    )
  }
  compiled <- run(TRUE)
  uncompiled <- withr::with_options(
    list(covr.install_compile = FALSE),
    run(FALSE)
  )

  expect_equal(
    as.data.frame(uncompiled)[c("first_line", "value")],
    as.data.frame(compiled)[c("first_line", "value")]
  )
})

test_that("install_compile() reads the option and COVR_INSTALL_COMPILE", {
  expect_true(withr::with_envvar(
    c(COVR_INSTALL_COMPILE = NA),
    install_compile()
  ))
  expect_false(
    withr::with_envvar(c(COVR_INSTALL_COMPILE = "false"), install_compile())
  )
  expect_true(
    withr::with_options(
      list(covr.install_compile = TRUE),
      withr::with_envvar(c(COVR_INSTALL_COMPILE = "false"), install_compile())
    )
  )
})

test_that("instrumenting after installing gives the traces of instrumenting when loaded", {
  skip_on_cran()
  run <- function() {
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = "TestInstrument::g(2)"
    )
  }
  after_install <- run()
  when_loaded <- local({
    local_mocked_bindings(instrument_package = function(...) NULL)
    run()
  })

  traces <- function(cov) {
    df <- as.data.frame(cov)
    df[
      order(df$first_line, df$first_column, df$last_line),
      c(
        "first_line",
        "first_column",
        "last_line",
        "last_column",
        "value"
      )
    ]
  }
  expect_gt(nrow(traces(after_install)), 8L)
  expect_equal(traces(after_install), traces(when_loaded), ignore_attr = TRUE)
})
