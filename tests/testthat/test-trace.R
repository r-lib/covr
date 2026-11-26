test_that("re-tracing an already traced namespace keeps the counts (#641)", {
  cov <- package_coverage(
    test_path("TestSummary"),
    type = "none",
    code = c(
      "invisible(TestSummary::test_me(1, 2))",
      "covr:::trace_environment(asNamespace('TestSummary'), scope = 'TestSummary')"
    )
  )
  expect_equal(percent_coverage(cov), 50)
})

test_that("save_trace writes only complete covr_trace_ files", {
  dir <- withr::local_tempdir()
  save_trace(dir)
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  expect_length(files, 1)
  expect_match(files, "^covr_trace_")
  expect_no_error(readRDS(file.path(dir, files)))
})

test_that("save_trace writes an error marker when serialization fails", {
  local_mocked_bindings(
    save_rds = function(object, file) {
      if (!inherits(object, "covr_trace_error")) {
        stop("boom")
      }
      saveRDS(object, file)
    }
  )
  dir <- withr::local_tempdir()
  save_trace(dir)
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  expect_length(files, 1)
  expect_match(files, "^covr_trace_")
  expect_error(
    merge_coverage(file.path(dir, files)),
    "boom",
    class = "covr_error"
  )
})

test_that("save_trace does not save environments referenced by srcfiles", {
  # The srcfiles of installed packages have promises to lazy-load their lines
  # and parse data, evaluated in an environment that references the
  # environments of the package (#602). Packages can also add bindings to
  # srcfiles, e.g. this.path adds an environment.
  pkg_env <- new.env()
  srcfile <- srcfilecopy("R/f.R", character())
  delayedAssign("lines", "f <- function() 1", pkg_env, srcfile)
  delayedAssign("parseData", NULL, pkg_env, srcfile)
  srcfile$context <- new.env(parent = pkg_env)
  clear_counters()
  withr::defer(clear_counters())
  new_counter(srcref(srcfile, c(1, 1, 1, 17, 1, 17, 1, 1)), "f")

  local_mocked_bindings(
    save_rds = function(object, file) {
      saveRDS(object, file, refhook = function(env) {
        if (identical(env, pkg_env)) stop("saved the package environment")
      })
    }
  )
  trace <- merge_coverage(save_trace(withr::local_tempdir()))
  expect_equal(
    getSrcLines(attr(trace[[1]]$srcref, "srcfile"), 1, 1),
    "f <- function() 1"
  )
})

test_that("save_trace does not copy active bindings or unforced promises of srcfiles", {
  srcfile <- srcfilecopy("R/f.R", "f <- function() 1")
  makeActiveBinding("active", function() stop("ran active binding"), srcfile)
  delayedAssign("promise", stop("ran promise"), assign.env = srcfile)

  copy <- portable_srcfiles(list(srcfile))[[1]]
  expect_length(
    intersect(c("active", "promise"), ls(copy, all.names = TRUE)),
    0L
  )
  expect_equal(copy$lines, "f <- function() 1")
})

test_that("save_trace errors if the trace file can't be written", {
  local_mocked_bindings(save_rds = function(object, file) NULL)
  dir <- file.path(withr::local_tempdir(), "missing")
  err <- tryCatch(suppressWarnings(save_trace(dir)), error = conditionMessage)
  expect_match(err, "Can't write trace file")
})

test_that("unsaved_traces ignores the markers of the current process", {
  dir <- withr::local_tempdir()
  pid <- Sys.getpid()
  file.create(file.path(dir, paste0("covr_pending_", pid, "_a")))
  file.create(file.path(dir, paste0("covr_pending_", pid, "0_b")))

  expect_equal(unsaved_traces(dir), paste0("covr_pending_", pid, "0_b"))
})

test_that("save_registered_traces() saves the others if one can't be saved", {
  local_clean_traces()
  dir <- withr::local_tempdir()
  a <- scope_entry("a")
  a$trace_dir <- file.path(dir, "removed")
  b <- scope_entry("b")
  b$trace_dir <- dir

  save_registered_traces()

  expect_length(list.files(dir, pattern = "^covr_trace_"), 1)
})

test_that("save_trace_and_clear() only clears the markers of its package", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(save_trace = function(...) NULL)
  register_trace(new.env(), dir, scope = "pkg")
  register_trace(new.env(), dir, scope = "pkg2")

  save_trace_and_clear(dir, "pkg")

  expect_match(list.files(dir), "^covr_pending_[0-9]+_pkg2_")
})

test_that("traces are read with the counters they copied to their directory", {
  dir <- withr::local_tempdir()
  lib <- withr::local_tempdir()
  src <- srcfilecopy("a.R", "x")
  counters <- list(
    "pkg/a.R:1:1:1:1:1:1:1:1" = list(
      value = 0,
      srcref = srcref(src, c(1, 1, 1, 1)),
      functions = "f"
    )
  )
  counters_file <- file.path(lib, "covr_counters.rds")
  saveRDS(counters, counters_file)
  local_mocked_bindings(
    process_trace = function(scope) {
      structure(
        list(
          counters_file = counters_file,
          counts = c("pkg/a.R:1:1:1:1:1:1:1:1" = 2),
          counters = list()
        ),
        class = "covr_counts"
      )
    }
  )
  save_trace(dir, "pkg")
  save_trace(dir, "pkg")
  unlink(lib, recursive = TRUE)

  expect_length(list.files(dir, pattern = "^covr_counters_"), 1)
  expect_equal(merge_traces(dir)[[1]]$value, 4)
})

test_that("process_trace() of a scope only saves the traces of that scope", {
  local_clean_traces()
  src <- srcfilecopy("a.R", "x")
  ref <- srcref(src, c(1, 1, 1, 1))
  counter <- list(value = 0, srcref = ref, functions = "f")
  .counters[["A/a.R:1"]] <- counter
  .counters[["A/b.R:1"]] <- counter
  .counters[["B/a.R:1"]] <- counter
  .counters[["c.R:1"]] <- counter
  register_count(c("A/a.R:1", "B/a.R:1"))
  entry <- scope_entry("A")
  entry$counters_file <- "counters_A.rds"
  entry$counters_keys <- "A/a.R:1"
  .Call(covr_count, "A/a.R:1")
  .Call(covr_count, "B/a.R:1")
  sync_counts()

  trace <- process_trace("A")
  expect_s3_class(trace, "covr_counts")
  expect_equal(trace$counters_file, "counters_A.rds")
  expect_equal(trace$counts, c("A/a.R:1" = 1))
  expect_named(trace$counters, "A/b.R:1")

  # Without restored counters all the traces of the scope are saved
  expect_named(process_trace("B"), "B/a.R:1")
  expect_named(process_trace(""), "c.R:1")
  expect_setequal(names(process_trace()), ls(.counters))
})

test_that("untrace_scope() releases the traced environment", {
  local_clean_traces()
  freed <- FALSE
  local({
    env <- new.env(parent = globalenv())
    reg.finalizer(env, function(e) freed <<- TRUE)
    eval(parse(text = "f <- function(x) x + 1", keep.source = TRUE), env)
    with_coverage(env$f(1), env = env)
  })
  gc()
  expect_identical(freed, TRUE)
})

test_that("untrace_scope() of an untraced scope leaves other tracing alone", {
  local_clean_traces()
  env <- new.env(parent = globalenv())
  eval(parse(text = "f <- function(x) x + 1", keep.source = TRUE), env)
  orig <- body(env$f)

  trace_environment(env, scope = "a")
  untrace_scope("a")
  expect_identical(body(env$f), orig)

  trace_environment(env, scope = "b")
  untrace_scope("a")
  expect_identical(is_traced(env$f), TRUE)

  untrace_scope()
  expect_identical(body(env$f), orig)
})

test_that("untracing the anonymous scope leaves the Shiny scope traced", {
  local_clean_traces()
  app <- new.env(parent = globalenv())
  eval(parse(text = "f <- function(x) x + 1", keep.source = TRUE), app)
  local({
    local_scope(shiny_scope)
    trace_replacement(replacement("f", env = app), shiny_scope)
  })
  other <- new.env(parent = globalenv())
  eval(parse(text = "g <- function(x) x", keep.source = TRUE), other)

  with_coverage(other$g(1), env = other)
  expect_identical(is_traced(app$f), TRUE)
  app$f(1)
  sync_counts()
  expect_equal(
    unname(unlist(lapply(scope_counters(shiny_scope), `[[`, "value"))),
    1
  )

  untrace_scope(shiny_scope)
  expect_identical(is_traced(app$f), FALSE)
})
