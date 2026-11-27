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
        "keys <- grep('^TestInstrument/<text>', ls(covr:::.counters), value = TRUE)",
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
  local_clean_traces()
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
  withr::local_options(covr.install_instrument = FALSE)
  cov <- package_coverage(
    test_path("TestInstrument"),
    type = "none",
    code = "TestInstrument::f(1)"
  )

  df <- as.data.frame(cov)
  expect_equal(df$value[df$first_line == 16L], 1)
  expect_equal(df$value[df$first_line == 18L], 0)
})

test_that("process_status() decodes the status of a process", {
  skip_on_os("windows")
  status <- function(command) {
    pid <- sys::exec_background("sh", c("-c", command))
    process_status(pid, wait = TRUE)
  }
  expect_identical(status("exit 0"), 0L)
  expect_identical(status("exit 3"), 3L)
  # Killed by a signal, as `SIGKILL` and `SIGINT` are
  expect_identical(status("kill -9 $$"), -1L)
  expect_identical(status("kill -2 $$"), -1L)

  pid <- sys::exec_background("sleep", "5")
  withr::defer(tools::pskill(pid, tools::SIGKILL))
  expect_true(is.na(process_status(pid, wait = FALSE)))
  tools::pskill(pid, tools::SIGKILL)
  expect_identical(process_status(pid, wait = TRUE), -1L)
})

test_that("instrument_package() doesn't read files while the process runs", {
  skip_on_os("windows")
  pkg <- list(package = "pkg")
  lib <- withr::local_tempdir()
  killed <- FALSE
  local_mocked_bindings(
    start_instrument = function(...) {
      list(pkg = pkg, install_path = lib, pid = 1L, output = character())
    },
    # As an interrupt while waiting does
    process_status = function(...) stop("interrupted"),
    cancel_instrument = function(jobs) killed <<- TRUE
  )
  expect_error(instrument_package(pkg, lib), "interrupted")
  expect_true(killed)
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
  local_clean_traces()
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
  local_clean_traces()
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
  local_clean_traces()
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
    withr::local_options(covr.install_instrument = FALSE)
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

test_that("restore_counters() keeps the counters and counts of other packages", {
  local_clean_traces()
  local_mocked_bindings(env_scope = function(env) attr(env, "scope"))
  save_counters <- function(key) {
    file <- withr::local_tempfile(.local_envir = parent.frame())
    counters <- new.env()
    counters[[key]] <- list(value = 0, functions = "f")
    saveRDS(counters, file)
    file
  }
  file_a <- save_counters("A/a.R:1:1")
  file_b <- save_counters("B/a.R:1:1")
  ns_a <- structure(new.env(), scope = "A")
  ns_b <- structure(new.env(), scope = "B")

  restore_counters(ns_a, file_a)
  .Call(covr_count, "A/a.R:1:1")
  restore_counters(ns_b, file_b)
  sync_counts()

  expect_equal(.counters[["A/a.R:1:1"]]$value, 1)
  expect_equal(.counters[["B/a.R:1:1"]]$value, 0)
  expect_equal(scope_entry("A")$counters_file, file_a)
  expect_equal(scope_entry("B")$counters_file, file_b)
  expect_equal(scope_entry("A")$counters_keys, "A/a.R:1:1")
  expect_equal(process_trace("B")$counters_file, file_b)
})

test_that("restore_counters() saves the counts of a package loaded from another library", {
  local_clean_traces()
  local_mocked_bindings(env_scope = function(env) attr(env, "scope"))
  save_counters <- function() {
    file <- withr::local_tempfile(.local_envir = parent.frame())
    counters <- new.env()
    counters[["A/a.R:1:1"]] <- list(value = 0, functions = "f")
    saveRDS(counters, file)
    file
  }
  file1 <- save_counters()
  file2 <- save_counters()
  traces <- withr::local_tempdir()
  ns1 <- structure(new.env(), scope = "A")
  ns2 <- structure(new.env(), scope = "A")

  restore_counters(ns1, file1)
  entry <- scope_entry("A")
  entry$trace_dir <- traces
  .Call(covr_count, "A/a.R:1:1")
  restore_counters(ns2, file2)
  sync_counts()

  # The counts of the first library are saved, with its counters
  saved <- list.files(traces, "^covr_trace_", full.names = TRUE)
  expect_length(saved, 1L)
  trace <- readRDS(saved)
  expect_equal(
    basename(trace$counters_file),
    paste0("covr_counters_", unname(tools::md5sum(file1)), ".rds")
  )
  expect_equal(unname(trace$counts), 1)
  # The second one starts from zero
  expect_equal(.counters[["A/a.R:1:1"]]$value, 0)
  expect_equal(scope_entry("A")$counters_file, file2)
  expect_identical(scope_entry("A")$env, ns2)

  # Back to the first library
  restore_counters(ns1, file1)
  expect_equal(scope_entry("A")$counters_file, file1)
})
