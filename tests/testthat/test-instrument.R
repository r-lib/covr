test_that("package_coverage() loads an instrumented and byte-compiled package", {
  skip_on_cran()
  local_install_defaults()
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
  expect_equal(df$value[df$first_line == 16L], 2)
  expect_equal(df$value[df$first_line == 18L], 0)
})

test_that("package_coverage() instruments functions that .onLoad() creates", {
  skip_on_cran()
  local_install_defaults()
  log <- withr::local_tempfile()
  cov <- withr::with_envvar(
    c(TESTINSTRUMENT_LOG = log),
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        "stopifnot(covr:::is_traced(TestInstrument:::made))",
        "stopifnot(covr:::is_traced(TestInstrument:::made_lazy))",
        "stopifnot(TestInstrument:::made(1) == 2)",
        "stopifnot(TestInstrument:::made_lazy(1) == 23)",
        "covr:::sync_counts()",
        "keys <- grep('^<text>', ls(covr:::.counters), value = TRUE)",
        "stopifnot(length(keys) > 0)",
        "stopifnot(sum(vapply(keys, function(k) covr:::.counters[[k]]$value, numeric(1))) > 0)",
        "TestInstrument::f(1)"
      )
    )
  )

  expect_length(readLines(log), 2L)
  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 16L], 1)
  expect_equal(df$value[df$first_line == 18L], 0)
})

test_that("branch coverage of the saved code survives loading the package again", {
  skip_on_cran()
  local_install_defaults()
  cov <- withr::with_options(
    list(covr.branch_coverage = TRUE),
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        "unloadNamespace('TestInstrument')",
        "loadNamespace('TestInstrument')",
        "TestInstrument::g(2)",
        "counts <- vapply(as.list(covr:::.counters$branches), function(x) sum(x$value), numeric(1))",
        "stopifnot(length(counts) > 1, any(counts > 0))"
      )
    )
  )

  expect_gt(length(attr(cov, "branches")), 1L)
})

test_that("instrument_package() returns the file with the counters", {
  skip_on_cran()
  local_install_defaults()
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)

  db <- file.path(lib, "TestInstrument", "R", "TestInstrument.rdb")
  original <- unname(tools::md5sum(db))

  file <- instrument_package(pkg, lib)
  expect_equal(file, file.path(lib, "TestInstrument", "R", "covr_counters.rds"))
  # The installed code is left as it is, next to the instrumented code
  expect_equal(unname(tools::md5sum(db)), original)
  expect_contains(
    list.files(file.path(lib, "TestInstrument", "R")),
    "TestInstrument.covr.rdb"
  )
  counters <- readRDS(file)
  expect_gt(length(ls(counters)), 0L)
  values <- unname(vapply(as.list(counters), function(x) x$value, numeric(1)))
  expect_equal(values, rep(0, length(values)))
})

test_that("instrument_package() leaves packages with functions in sysdata.rda", {
  skip_on_cran()
  local_install_defaults()
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

test_that("instrument_installed_package() leaves the installed package if it fails", {
  skip_on_cran()
  local_install_defaults()
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  withr::defer(unloadNamespace("TestInstrument"))
  local_mocked_bindings(
    portable_srcfiles = function(...) {
      stop(structure(
        class = c("covr_test_failure", "error", "condition"),
        list(message = "failed", call = NULL)
      ))
    }
  )

  expect_error(
    instrument_installed_package("TestInstrument", lib),
    class = "covr_test_failure"
  )
  expect_equal(
    sort(list.files(file.path(lib, "TestInstrument", "R"))),
    c("TestInstrument", "TestInstrument.rdb", "TestInstrument.rdx")
  )
})

test_that("instrument_package() instruments packages with only data in sysdata.rda", {
  skip_on_cran()
  local_install_defaults()
  src <- withr::local_tempdir()
  file.copy(test_path("TestInstrument"), src, recursive = TRUE)
  x <- 1
  save(x, file = file.path(src, "TestInstrument", "R", "sysdata.rda"))
  lib <- withr::local_tempdir()
  pkg <- as_package(file.path(src, "TestInstrument"))
  install_package(pkg, lib, getOption("covr.flags"), TRUE, byte_compile = FALSE)

  expect_false(has_sysdata_functions("TestInstrument", lib))
  withr::local_options(covr.full_traversal = TRUE)
  expect_true(has_sysdata_functions("TestInstrument", lib))
})

test_that("instrument_package() warns if the package can't be instrumented", {
  skip_on_cran()
  local_install_defaults()
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
  local_install_defaults()
  local_mocked_bindings(instrument_package = function(...) NULL)
  cov <- package_coverage(
    test_path("TestInstrument"),
    type = "none",
    code = "TestInstrument::f(1)"
  )

  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 16L], 1)
  expect_equal(df$value[df$first_line == 18L], 0)
})

test_that("restore_counters() errors without the saved counters", {
  file <- file.path(withr::local_tempdir(), "covr_counters.rds")
  expect_snapshot(
    restore_counters(new.env(), file),
    error = TRUE,
    transform = function(x) sub(file, "<file>", x, fixed = TRUE)
  )
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

test_that("restore_counters() errors if `.onLoad()` defined a `.Call` that masks the saved counters", {
  clear_counters()
  withr::defer(clear_counters())
  withr::defer(the$traced_env <- NULL)
  withr::defer(the$trace_error <- NULL)
  file <- withr::local_tempfile()
  counters <- new.env()
  counters[["a.R:1:1"]] <- list(value = 0, functions = "a")
  attr(counters, "maskable") <- TRUE
  saveRDS(counters, file)
  ns <- new.env()
  attr(ns, "name") <- "pkg"
  ns$.Call <- function(...) base::.Call(...)

  expect_snapshot(restore_counters(ns, file), error = TRUE)
  # The error replaces the trace that the process saves
  marker <- readRDS(save_trace(withr::local_tempdir()))
  expect_s3_class(marker, "covr_trace_error")
  expect_match(marker$message, ".onLoad()", fixed = TRUE)

  # Saved counters that are compiled or call `base::.Call` can't be masked
  the$trace_error <- NULL
  attr(counters, "maskable") <- FALSE
  saveRDS(counters, file)
  restore_counters(ns, file)
  expect_contains(ls(.counters), "a.R:1:1")
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

test_that("package_coverage() stores the instrumented functions compiled", {
  skip_on_cran()
  local_install_defaults()
  cov <- package_coverage(
    test_path("TestInstrument"),
    type = "none",
    code = c(
      "stopifnot(TestInstrument::is_compiled(TestInstrument::f))",
      "TestInstrument::f(1)"
    )
  )
  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 16L], 1)
})

test_that("covr.install_instrument = FALSE instruments when the package is loaded", {
  skip_on_cran()
  local_install_defaults()
  install_path <- withr::local_tempfile()
  cov <- withr::with_options(
    list(covr.install_instrument = FALSE),
    package_coverage(
      test_path("TestInstrument"),
      type = "none",
      code = c(
        "stopifnot(!TestInstrument::is_compiled(TestInstrument::f))",
        "TestInstrument::f(1)",
        "TestInstrument::f(2)"
      ),
      clean = FALSE,
      install_path = install_path
    )
  )

  files <- list.files(file.path(install_path, "TestInstrument", "R"))
  expect_equal(
    files,
    c("TestInstrument", "TestInstrument.rdb", "TestInstrument.rdx")
  )
  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 16L], 2)
  expect_equal(df$value[df$first_line == 18L], 0)
})

test_that("install_instrument() reads the option and COVR_INSTALL_INSTRUMENT", {
  local_install_defaults()
  expect_true(install_instrument())
  expect_false(
    withr::with_envvar(
      c(COVR_INSTALL_INSTRUMENT = "false"),
      install_instrument()
    )
  )
  expect_true(
    withr::with_options(
      list(covr.install_instrument = TRUE),
      withr::with_envvar(
        c(COVR_INSTALL_INSTRUMENT = "false"),
        install_instrument()
      )
    )
  )
  expect_false(
    withr::with_options(
      list(covr.install_instrument = FALSE),
      withr::with_envvar(
        c(COVR_INSTALL_INSTRUMENT = "true"),
        install_instrument()
      )
    )
  )
  expect_false(
    withr::with_envvar(
      c(COVR_INSTALL_INSTRUMENT = "No"),
      install_instrument()
    )
  )
})

test_that("COVR_INSTALL_INSTRUMENT=false instruments when the package is loaded", {
  skip_on_cran()
  local_install_defaults()
  withr::local_envvar(COVR_INSTALL_INSTRUMENT = "false")
  install_path <- withr::local_tempfile()
  package_coverage(
    test_path("TestInstrument"),
    type = "none",
    code = "TestInstrument::f(1)",
    clean = FALSE,
    install_path = install_path
  )

  expect_false(
    file.exists(file.path(
      install_path,
      "TestInstrument",
      "R",
      "covr_counters.rds"
    ))
  )
})

test_that("instrumenting after installing gives the traces of instrumenting when loaded", {
  skip_on_cran()
  local_install_defaults()
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

  # The functions of `g()`, as the functions that `.onLoad()` calls run at
  # different times when instrumenting when loaded
  traces <- function(cov) {
    df <- as.data.frame(cov)
    df <- df[df$first_line %in% 26:31, ]
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
  expect_gt(nrow(traces(after_install)), 4L)
  expect_equal(traces(after_install), traces(when_loaded), ignore_attr = TRUE)
})
