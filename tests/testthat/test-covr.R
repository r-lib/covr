test_that("function_coverage", {
  withr::with_options(c(keep.source = TRUE), {
    f <- function(x) {
      x + 1
    }
    expect_equal(
      as.numeric(function_coverage("f", env = environment(f))[[1]]$value),
      0
    )

    expect_equal(
      as.numeric(function_coverage("f", env = environment(f), f(1))[[1]]$value),
      1
    )

    expect_equal(
      as.numeric(
        function_coverage("f", env = environment(f), f(1), f(1))[[1]]$value
      ),
      2
    )
  })
})

test_that("function_coverage identity function", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x) {
      x
    }

    cov_num <- function(...) {
      as.numeric(
        function_coverage("fun", env = environment(fun), ...)[[1]]$value
      )
    }

    expect_equal(cov_num(), 0)
    expect_equal(cov_num(fun(1)), 1)
  })
})

test_that("function_coverage return last expr", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function(x = 1) {
      x
      x <- 1
    }

    cov_fun <- function(...) {
      vdapply(
        function_coverage("fun", env = environment(fun), ...),
        "[[",
        "value"
      )
    }

    expect_equal(as.numeric(cov_fun()), c(0L, 0L))
    expect_equal(as.numeric(cov_fun(fun())), c(1L, 1L))
  })
})

test_that("duplicated first_line", {
  withr::with_options(c(keep.source = TRUE), {
    fun <- function() {
      # fmt: skip
      res <- lapply(1:2, function(x) { x + 1 }) # nolint
    }
    cov <- function_coverage("fun", env = environment(fun))
    first_lines <- as.data.frame(cov)$first_line
    expect_equal(length(first_lines), 2)
    expect_equal(first_lines[1], first_lines[2])
  })
})

test_that("trace calls handles all possibilities", {
  expr <- expression(y <- x * 10)

  expect_equal(trace_calls(expr), expr)

  expect_equal(trace_calls(list(expr)), list(expr))
})

covr_error_for <- function(lines, prompt = TRUE) {
  td <- tempfile()
  dir.create(td)
  withr::defer(unlink(td, recursive = TRUE), parent.frame())
  writeLines(
    c(if (prompt) c("header", ">"), lines),
    file.path(td, "x.Rout.fail")
  )
  err <- tryCatch(show_failures(td), covr_error = function(e) e)
  err$file <- "x.Rout.fail"
  err
}

test_that("covr_error keeps full output and a bounded message", {
  skip_if_not(l10n_info()$`UTF-8`)
  td <- tempfile()
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE))
  out <- file.path(td, "test.Rout.fail")
  body <- paste0("\u2714 line ", 1:200, " \u2550\u2550")
  # multibyte body where bytes - warning.length exceeds nchar (old bug)
  writeLines(
    enc2utf8(c("R version header", "more header", ">", body)),
    out,
    useBytes = TRUE
  )
  expect_gt(sum(nchar(body, "bytes")) - 300, sum(nchar(body, "chars")))

  withr::local_options(warning.length = 300)
  err <- expect_error(show_failures(td), class = "covr_error")
  expect_equal(err$file, out)
  # header skipped, whole output kept
  expect_equal(err$output, c(">", body))
  msg <- conditionMessage(err)
  expect_lte(nchar(msg, "chars"), 300 - 9)
  expect_match(msg, "line 200", fixed = TRUE)
  expect_no_match(msg, "line 1 ", fixed = TRUE)
  expect_no_match(msg, "R version header", fixed = TRUE)
})

test_that("covr_error message is capped at the default number of lines", {
  withr::local_options(warning.length = 8170)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(grep("^line ", msg, value = TRUE), paste0("line ", 71:120))
  expect_length(err$output, 121)
})

test_that("covr.failure_lines sets the number of lines in the message and print", {
  withr::local_options(warning.length = 8170, covr.failure_lines = 5)
  err <- covr_error_for(paste0("line ", 1:120))
  msg <- strsplit(conditionMessage(err), "\n")[[1]]
  expect_equal(grep("^line ", msg, value = TRUE), paste0("line ", 116:120))
  expect_equal(
    utils::tail(strsplit(format(err), "\n")[[1]], 5),
    paste0("line ", 116:120)
  )
})

test_that("covr_error print shows the last n lines", {
  err <- covr_error_for(paste0("line ", 1:10))
  expect_snapshot({
    print(err, n = 3)
    print(err, n = Inf)
  })
})

test_that("show_failures handles output without a prompt", {
  err <- covr_error_for(c("a", "b"), prompt = FALSE)
  expect_equal(err$output, c("a", "b"))
})

test_that("covr_error message is only the header if warning.length is too small", {
  withr::local_options(warning.length = 100)
  err <- covr_error_for(paste0("line ", 1:3))
  msg <- conditionMessage(err)
  expect_match(msg, "Code run to compute coverage failed", fixed = TRUE)
  expect_no_match(msg, "line", fixed = TRUE)
  expect_length(err$output, 4)
})

test_that("covr_error truncates a single line that is too long", {
  withr::local_options(warning.length = 250)
  err <- covr_error_for(paste0(strrep("a", 500), "END"))
  msg <- conditionMessage(err)
  expect_lte(nchar(msg), 250 - 9)
  expect_match(msg, "\na+END$")
  expect_equal(nchar(err$output[[2]]), 503)
})

test_that("clean_coverage_tests works with degenerated objects", {
  obj <- list(
    a = list(tests = new.env()),
    tests = structure(
      list(structure(
        list("a", "b"),
        call_count = 1L
      )),
      names = ""
    ),
    b = list(value = integer(0)),
    c = list(value = NA)
  )

  expect_no_error(
    covr:::clean_coverage_tests(obj)
  )
})

test_that("clean_coverage_tests keeps tallies with fewer rows than hits", {
  tally <- cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
  obj <- list(a = list(value = 3L, tests = as.environment(list(tally = tally))))

  clean_coverage_tests(obj)

  expect_equal(obj$a$tests$tally, tally)
})

test_that("merge_coverage_pair handles an object with an empty tests list", {
  tally <- cbind(test = 1L, call = 1L, depth = 0L, i = 1L)
  into <- list(
    tests = list(test1 = list(quote(a()))),
    a = list(value = 1L, tests = as.environment(list(tally = tally)))
  )
  from <- list(tests = list(), a = list(value = 2L))

  merged <- merge_coverage_pair(into, from)

  expect_equal(names(merged$tests), "test1")
  expect_equal(merged$a$value, 3L)
  expect_equal(merged$a$tests$tally, tally)
})

test_that("merge_coverage returns NULL for no coverage", {
  expect_null(merge_coverage(list()))
  expect_null(merge_coverage(character()))
})

test_that("in_covr() reflects R_COVR", {
  withr::local_envvar(R_COVR = "true")
  expect_equal(in_covr(), TRUE)

  withr::local_envvar(R_COVR = NA)
  expect_equal(in_covr(), FALSE)
})

test_that("merge_coverage sums the counts of shared traces", {
  a <- list(t1 = list(value = 1L), t2 = list(value = 2L))
  b <- list(t2 = list(value = 3L), t3 = list(value = 4L), t1 = list(value = 5L))
  merged <- merge_coverage(list(a, b))
  expect_equal(names(merged), c("t1", "t2", "t3"))
  expect_equal(
    vapply(merged, `[[`, integer(1), "value"),
    c(t1 = 6L, t2 = 5L, t3 = 4L)
  )
})

test_that("c() adds the counts of shared traces and appends the others", {
  src <- withr::local_tempfile(
    lines = c(
      "add <- function(x, y) {",
      "  x + y",
      "}",
      "subtract <- function(x, y) {",
      "  x - y",
      "}"
    ),
    fileext = ".R"
  )
  test_add <- withr::local_tempfile(lines = "add(1, 2)", fileext = ".R")
  test_both <- withr::local_tempfile(
    lines = c("add(1, 2)", "subtract(2, 1)"),
    fileext = ".R"
  )
  cov_add <- file_coverage(src, test_add)
  cov_both <- file_coverage(src, test_both)

  merged <- c(cov_add, cov_both)
  expect_s3_class(merged, "coverage")
  expect_equal(tally_coverage(merged)$value, c(2, 1))
  expect_equal(percent_coverage(cov_add), 50)
  expect_equal(percent_coverage(merged), 100)

  other <- code_coverage("f <- function() 1", "f()")
  appended <- c(cov_add, other)
  expect_equal(names(appended), c(names(cov_add), names(other)))
  expect_equal(appended[[names(other)]]$value, 1)
})

test_that("c() keeps the first object's attributes and unions excluded lines", {
  x <- structure(
    list(t1 = list(value = 1L)),
    package = list(package = "pkg", path = "a"),
    root = "a",
    excluded_lines = list(R.R = c(1, 3)),
    class = "coverage"
  )
  y <- structure(
    list(t1 = list(value = 2L)),
    package = list(package = "pkg", path = "b"),
    root = "b",
    excluded_lines = list(R.R = c(2, 3), S.R = 4),
    class = "coverage"
  )
  merged <- c(x, y)
  expect_equal(attr(merged, "package")$path, "a")
  expect_equal(attr(merged, "root"), "a")
  expect_equal(
    attr(merged, "excluded_lines"),
    list(R.R = c(1, 2, 3), S.R = 4)
  )
})

test_that("c() errors for coverage of different packages", {
  cov <- function(package) {
    structure(
      list(t1 = list(value = 1L)),
      package = if (!is.null(package)) list(package = package),
      class = "coverage"
    )
  }
  expect_error(c(cov("a"), cov("b")), class = "covr_combine_error")
  expect_error(c(cov("a"), cov(NULL)), class = "covr_combine_error")
  expect_equal(c(cov(NULL), cov(NULL))$t1$value, 2L)
})

test_that("c() errors if an argument isn't a coverage object", {
  cov <- structure(list(t1 = list(value = 1L)), class = "coverage")
  expect_error(
    c(cov, list(t1 = list(value = 1L))),
    class = "covr_combine_error"
  )
})

test_that("c() drops NULL arguments", {
  cov <- structure(list(t1 = list(value = 1L)), class = "coverage")
  expect_equal(c(cov, NULL, cov)$t1$value, 2L)
})

test_that("c() only keeps the type if all objects have it", {
  cov <- function(type) {
    structure(list(t1 = list(value = 1L)), type = type, class = "coverage")
  }
  expect_equal(attr(c(cov("tests"), cov("tests")), "type"), "tests")
  expect_null(attr(c(cov("tests"), cov("examples")), "type"))
  expect_null(attr(c(cov("tests"), cov(NULL)), "type"))
})

test_that("re-tracing an already traced namespace keeps the counts (#641)", {
  cov <- package_coverage(
    test_path("TestSummary"),
    type = "none",
    code = c(
      "invisible(TestSummary::test_me(1, 2))",
      "covr:::trace_environment(asNamespace('TestSummary'))"
    )
  )
  expect_equal(percent_coverage(cov), 50)
})

test_that("package_coverage keeps install_path only when coverage fails", {
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)
  expect_error(
    package_coverage(test_path("TestFailure"), install_path = install_path),
    class = "covr_error"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")

  install_path <- tempfile("R_LIBS")
  package_coverage(test_path("TestSummary"), install_path = install_path)
  expect_false(dir.exists(install_path))
})

test_that("package_coverage passes outDir to testInstalledPackage", {
  out_dir <- file.path(tempfile(), "out")
  on.exit(unlink(dirname(out_dir), recursive = TRUE), add = TRUE)
  package_coverage(test_path("TestSummary"), outDir = out_dir)
  expect_contains(
    list.files(out_dir, recursive = TRUE),
    "TestSummary-tests/testthat.Rout"
  )
})

test_that("package_coverage gives the reason the package can't be installed", {
  pkg <- withr::local_tempdir()
  writeLines(
    c("Package: Broken", "Version: 0.1"),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("", file.path(pkg, "NAMESPACE"))
  dir.create(file.path(pkg, "R"))
  writeLines("f <- function( {", file.path(pkg, "R", "f.R"))
  err <- tryCatch(package_coverage(pkg), error = identity)
  expect_match(conditionMessage(err), "Can't install")
  expect_match(conditionMessage(err), "unexpected")
})

test_that("package_coverage shows messages and warnings unless quiet", {
  local_mocked_bindings(
    run_commands = function(...) {
      message("a message")
      warning("a warning")
    }
  )
  expect_no_message(expect_no_warning(
    package_coverage(test_path("TestS4"), type = "none", quiet = TRUE)
  ))
  expect_message(
    expect_warning(
      package_coverage(test_path("TestS4"), type = "none", quiet = FALSE),
      "a warning"
    ),
    "a message"
  )
})

test_that("install_package shows the installation output unless quiet", {
  lib <- withr::local_tempdir()
  pkg <- as_package(test_path("TestS4"))
  install_package(pkg, lib, character(), quiet = FALSE)
  expect_contains(list.files(lib), "TestS4")
})

test_that("copy_installed_package gives the reasons the copy failed", {
  pkg <- local_installed_package("TestSummary", "--with-keep.source")
  err <- tryCatch(
    copy_installed_package(as_package(pkg), file.path(tempfile(), "lib")),
    error = conditionMessage
  )
  expect_match(err, "Can't copy the installed package TestSummary")
  # the reasons are the warnings of `file.copy()`, not the fallback
  expect_no_match(err, "`file.copy()` failed.", fixed = TRUE)
})

test_that("copy_installed_package fails if the copy has no DESCRIPTION", {
  pkg <- list(package = "pkg", path = file.path(withr::local_tempdir(), "pkg"))
  dir.create(pkg$path)
  err <- tryCatch(
    copy_installed_package(pkg, withr::local_tempdir()),
    error = conditionMessage
  )
  expect_match(err, "`file.copy()` failed.", fixed = TRUE)
})

test_that("run_vignettes reports failures to build the vignettes", {
  lib <- withr::local_tempdir()
  pkg <- list(package = "TestMissing", path = file.path(lib, "missing"))
  expect_error(run_vignettes(pkg, lib), class = "covr_error")
})

test_that("package_coverage measures installed packages (#638)", {
  pkg <- local_installed_package(
    "TestSummary",
    c("--install-tests", "--with-keep.source")
  )
  df <- as.data.frame(package_coverage(pkg))
  expect_equal(unique(df$filename), "R/TestSummary.R")
  expect_equal(df$first_line, c(5, 6, 8, 13))
  expect_equal(df$value, c(1, 1, 0, 0))
})

test_that("package_coverage needs tests and srcrefs of installed packages", {
  install_path <- file.path(withr::local_tempdir(), "lib")
  pkg <- local_installed_package("TestSummary", "--with-keep.source")
  expect_snapshot(
    package_coverage(pkg, install_path = install_path),
    error = TRUE
  )
  pkg <- local_installed_package(
    "TestSummary",
    c("--install-tests", "--without-keep.source")
  )
  expect_snapshot(
    package_coverage(pkg, install_path = install_path),
    error = TRUE
  )
})

test_that("package_coverage errors carry the full testthat output", {
  err <- expect_error(
    package_coverage(test_path("TestFailure")),
    class = "covr_error"
  )
  expect_true(file.exists(err$file))
  expect_match(paste(err$output, collapse = "\n"), "this test fails")
})

test_that("package_coverage errors on test failures by default", {
  expect_error(
    package_coverage(test_path("TestFailure")),
    "this test fails",
    class = "covr_error"
  )
})

test_that("covr.allow_failures returns coverage despite test failures", {
  withr::local_options(covr.allow_failures = TRUE)
  install_path <- tempfile("R_LIBS")
  on.exit(unlink(install_path, recursive = TRUE), add = TRUE)
  expect_warning(
    cov <- package_coverage(
      test_path("TestFailure"),
      install_path = install_path
    ),
    "this test fails",
    class = "covr_warning"
  )
  fail_files <- list.files(install_path, pattern = "fail$", recursive = TRUE)
  expect_equal(basename(fail_files), "testthat.Rout.fail")
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["covered"]], 0)
  expect_equal(values[["not_covered"]], 0)
})

test_that("merge_coverage reports corrupt trace files with a covr_error", {
  dir <- withr::local_tempdir()
  good <- file.path(dir, "covr_trace_good")
  bad <- file.path(dir, "covr_trace_bad")
  saveRDS(list(t1 = list(value = 1L)), good)
  writeBin(head(readBin(good, "raw", 1000), 10), bad)

  expect_error(
    merge_coverage(c(good, bad)),
    "covr_trace_bad.*incomplete",
    class = "covr_error"
  )
})

test_that("merge_coverage reports error markers with the original message", {
  dir <- withr::local_tempdir()
  marker <- file.path(dir, "covr_trace_marker")
  saveRDS(
    structure(
      list(message = "cannot serialize ALTREP", pid = 123L),
      class = "covr_trace_error"
    ),
    marker
  )

  expect_error(
    merge_coverage(marker),
    "covr_trace_marker.*cannot serialize ALTREP",
    class = "covr_error"
  )
})

test_that("bad trace files can be skipped with the covr_continue restart", {
  dir <- withr::local_tempdir()
  good <- file.path(dir, "covr_trace_good")
  bad <- file.path(dir, "covr_trace_bad")
  saveRDS(list(t1 = list(value = 1L)), good)
  writeBin(as.raw(1:5), bad)

  merged <- withCallingHandlers(
    merge_coverage(c(bad, good)),
    covr_error = function(e) invokeRestart("covr_continue")
  )
  expect_equal(merged$t1$value, 1L)
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
  expect_false(any(c("active", "promise") %in% ls(copy, all.names = TRUE)))
  expect_equal(copy$lines, "f <- function() 1")
})

test_that("save_trace errors if the trace file can't be written", {
  local_mocked_bindings(save_rds = function(object, file) NULL)
  dir <- file.path(withr::local_tempdir(), "missing")
  err <- tryCatch(suppressWarnings(save_trace(dir)), error = conditionMessage)
  expect_match(err, "Can't write trace file")
})

test_that("package_coverage reports bad trace files", {
  code <- paste0(
    "writeBin(as.raw(1:5), file.path(",
    "Sys.getenv('COVERAGE_DIR', .libPaths()[1]), 'covr_trace_corrupt'))"
  )
  pkg <- test_path("TestSummary")

  expect_error(
    package_coverage(pkg, type = "none", code = code, quiet = TRUE),
    "covr_trace_corrupt",
    class = "covr_error"
  )

  expect_warning(
    cov <- package_coverage(
      pkg,
      type = "none",
      code = code,
      quiet = TRUE,
      allow_failures = TRUE
    ),
    "covr_trace_corrupt",
    class = "covr_warning"
  )
  expect_s3_class(cov, "coverage")
  expect_gt(length(cov), 0)
})

test_that("package_coverage warns about processes that did not save a trace", {
  # Killing the process with SIGKILL relies on POSIX signals
  skip_on_os("windows")

  rscript <- function(code) {
    paste0(
      "system2(file.path(R.home('bin'), 'Rscript'), ",
      "c('--vanilla', '-e', shQuote('library(TestSummary); ",
      code,
      "')))"
    )
  }
  code <- c(
    rscript("test_me(1, 2)"),
    rscript("dont_test_me(1, 2); tools::pskill(Sys.getpid(), tools::SIGKILL)")
  )

  expect_snapshot(
    cov <- package_coverage(
      test_path("TestSummary"),
      type = "none",
      code = code
    )
  )
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["test_me"]], 0)
  expect_equal(values[["dont_test_me"]], 0)
})

test_that("package_coverage works if the site libraries are removed (#560)", {
  # for `.libPaths(include.site = FALSE)`
  skip_if(getRversion() < "4.1.0")

  # As renv does when it activates its sandbox, e.g. if the package imports
  # renv in an renv project, where this session has no site libraries. Site
  # libraries of this session are kept, as they could have covr's dependencies.
  site <- normalizePath(.Library.site, winslash = "/")
  script <- withr::local_tempfile(
    fileext = ".R",
    lines = c(
      sprintf("keep <- %s", paste(deparse(site), collapse = "")),
      "site <- setdiff(normalizePath(.Library.site, winslash = '/'), keep)",
      ".libPaths(setdiff(.libPaths(), site), include.site = FALSE)",
      "library(TestSummary)",
      "test_me(1, 2)"
    )
  )
  code <- sprintf(
    "stopifnot(system2(file.path(R.home('bin'), 'Rscript'), c('--vanilla', shQuote(%s))) == 0)",
    deparse(normalizePath(script, winslash = "/"))
  )

  cov <- package_coverage(test_path("TestSummary"), type = "none", code = code)
  values <- tapply(
    tally_coverage(cov)$value,
    tally_coverage(cov)$functions,
    sum
  )
  expect_gt(values[["test_me"]], 0)
})

test_that("R processes get only the site libraries of this session (#560)", {
  site_libraries <- function(site) {
    withr::local_envvar(R_LIBS_SITE = r_libs_site(site))
    system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "-e", shQuote("writeLines(.Library.site)")),
      stdout = TRUE
    )
  }

  expect_equal(site_libraries(character()), character())
  site <- normalize_path(withr::local_tempdir())
  expect_equal(normalize_path(site_libraries(site)), site)
})

test_that("unsaved_traces ignores the markers of the current process", {
  dir <- withr::local_tempdir()
  pid <- Sys.getpid()
  file.create(file.path(dir, paste0("covr_pending_", pid, "_a")))
  file.create(file.path(dir, paste0("covr_pending_", pid, "0_b")))

  expect_equal(unsaved_traces(dir), paste0("covr_pending_", pid, "0_b"))
})

test_that("active bindings are not read when looking for functions", {
  src <- paste(
    "makeActiveBinding('ab', function() stop('boom'), environment())",
    "f <- function() {",
    "  1",
    "}",
    sep = "\n"
  )
  for (full in c(FALSE, TRUE)) {
    withr::local_options(covr.full_traversal = full)
    cov <- as.data.frame(code_coverage(src, "f()"))
    expect_equal(cov$functions, "f")
    expect_equal(cov$value, 1)
  }
})

test_that("active bindings in a package are not read", {
  dir <- withr::local_tempdir()
  file.copy("TestFullTraversal", dir, recursive = TRUE)
  pkg <- file.path(dir, "TestFullTraversal")
  # Active bindings can't be defined at the top level of an installed package,
  # as saving them for lazy loading evaluates them.
  cat(
    ".onLoad <- function(libname, pkgname) {\n",
    "  makeActiveBinding('ab', function() stop('boom'), topenv())\n",
    "}\n",
    file = file.path(pkg, "R", "TestFullTraversal.R"),
    append = TRUE
  )
  for (full in c(FALSE, TRUE)) {
    withr::local_options(covr.full_traversal = full)
    cov <- as.data.frame(package_coverage(pkg))
    expect_true("api" %in% cov$functions)
  }
})

test_that("package_coverage(pre_clean =) is deprecated", {
  expect_snapshot(
    cov <- package_coverage(test_path("TestS4"), pre_clean = FALSE)
  )
  expect_gt(length(cov), 0)
})
