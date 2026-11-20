expect_parses <- function(lines) {
  expect_no_error(parse(text = lines, keep.source = FALSE))
}

test_that("covr_count_auto counts keys that are not registered", {
  key <- "covr-test-count-auto-key"
  on.exit(.Call(covr_counter_reset), add = TRUE)
  .Call(covr_counter_reset)

  # `covr_count()` ignores keys that are not registered
  .Call(covr_count, key)
  expect_false(key %in% names(.Call(covr_counter_take)))

  .Call(covr_count_auto, key)
  .Call(covr_count_auto, key)
  expect_equal(.Call(covr_counter_take)[[key]], 2)

  # The key keeps its count after the counts are taken
  .Call(covr_count, key)
  expect_equal(.Call(covr_counter_take)[[key]], 1)
})

test_that("counters call the routine in `the$count_routine`", {
  old <- the$count_routine
  on.exit(the$count_routine <- old, add = TRUE)
  clear_counters()
  on.exit(clear_counters(), add = TRUE)

  src <- srcfilecopy("a.R", "f <- function() 1")
  traced <- function() {
    1
  }
  attr(traced, "srcref") <- srcref(src, c(1, 6, 1, 17))
  attr(body(traced), "srcref") <- list(NULL, srcref(src, c(1, 17, 1, 17)))

  the$count_routine <- as.symbol(".covr_count")
  x <- trace_calls(traced)
  expect_true(any(grepl(".covr_count", deparse(body(x)), fixed = TRUE)))
  expect_true(is_traced(x))
  expect_false(any(grepl("covr:::", deparse(body(x)), fixed = TRUE)))
})

test_that("keys have full file names only for the code of base R", {
  old <- the$count_routine
  on.exit(the$count_routine <- old, add = TRUE)
  src <- srcfilecopy("/some/dir/a.R", "f <- 1")
  ref <- srcref(src, c(1, 1, 1, 6))

  the$count_routine <- NULL
  expect_equal(key(ref), "a.R:1:1:1:6:1:6:1:1")

  the$count_routine <- as.symbol(".covr_count")
  expect_equal(key(ref), "/some/dir/a.R:1:1:1:6:1:6:1:1")
})

test_that("function_definition finds the names and function of a definition", {
  defined <- function_definition(quote(a <- b <- function(x) x))
  expect_equal(defined$names, c("a", "b"))
  expect_equal(defined$fun, quote(function(x) x))

  expect_null(function_definition(quote(a <- 1)))
  expect_null(function_definition(quote(f(a <- function(x) x))))
})

test_that("same_function ignores source references", {
  parsed <- eval(parse(
    text = "function(x) {\n  if (x) {\n    1\n  }\n}",
    keep.source = TRUE
  )[[1]])
  plain <- eval(parse(
    text = "function(x) {\n  if (x) {\n    1\n  }\n}",
    keep.source = FALSE
  )[[1]])
  other <- eval(parse(
    text = "function(x) {\n  if (x) {\n    2\n  }\n}",
    keep.source = FALSE
  )[[1]])

  expect_false(identical(parsed, plain, ignore.bytecode = TRUE))
  expect_true(same_function(parsed, plain))
  expect_false(same_function(parsed, other))
})

test_that("is_fixed_body finds the bodies that code inspects", {
  expect_true(is_fixed_body(TRUE))
  expect_true(is_fixed_body(NULL))
  expect_true(is_fixed_body(quote(UseMethod("f"))))
  expect_true(is_fixed_body(quote({
    UseMethod("f")
  })))
  expect_false(is_fixed_body(quote(f(x))))
  expect_false(is_fixed_body(quote({
    x
    UseMethod("f")
  })))
})

test_that("add_pkg_r_hook makes a loader script read the instrumented code", {
  lines <- c(
    "local({",
    "    info <- loadingNamespaceInfo()",
    "    pkg <- info$pkgname",
    '    dbbase <- file.path(info$libname, pkg, "R", pkg)',
    "    lazyLoad(dbbase, ns)",
    "})"
  )
  expect_equal(
    add_pkg_r_hook(lines)[[4]],
    '    dbbase <- file.path(info$libname, pkg, "R", paste0(pkg, ".covr"))'
  )
  expect_error(add_pkg_r_hook(lines[-4]), "Can't find")
})

base_loader <- c(
  ".Internal(eval(quote({",
  "..lazyLoad <- function(filebase, envir = parent.frame())",
  "{",
  "    envhook <- function(n) {",
  "        if (existsInFrame(n, envenv))",
  "            envenv[[n]]",
  "        else {",
  "            e <- mkenv()",
  "            envenv[[n]] <- e           # MUST do this immediately",
  "            key <- env[[n]]",
  "            data <- lazyLoadDBfetch(key, datafile, compressed, envhook)",
  "            list2env(data$bindings, e)",
  "            if (! is.null(data$attributes))",
  "                attributes(e) <- data$attributes",
  "            e",
  "        }",
  "    }",
  "    this <- environment()",
  "}",
  '    basedb <- glue(.Internal(R.home()), "library", "base", "R",',
  '                   "base", sep= .Platform$file.sep)',
  "    ..lazyLoad(basedb, baseenv())",
  "}), .Internal(new.env(FALSE, baseenv(), 29L)), baseenv()))",
  "",
  "as.numeric <- as.double"
)

test_that("add_base_r_hook reads the instrumented code and counts it", {
  lines <- add_base_r_hook(
    base_loader,
    "/lib/covr/libs/covr.so",
    "/lib/base/R/covr_counters.rds",
    "/traces"
  )
  expect_parses(lines)
  expect_true(any(grepl('"base.covr", sep=', lines, fixed = TRUE)))
  # The srcfiles of the functions are environments with lazy bindings
  expect_true(any(grepl("data <- lazyLoadDBfetch(ekey", lines, fixed = TRUE)))
  expect_true(any(grepl("makeLazy(names(key$lazyKeys)", lines, fixed = TRUE)))

  # The hook is after the code of base is read, and before the rest of the script
  end <- grep("baseenv()))", lines, fixed = TRUE)
  count <- grep("^[.]covr_count <- ", lines)
  expect_gt(count, end)
  expect_lt(count, grep("^as.numeric", lines))
  expect_true(any(grepl("/lib/covr/libs/covr.so", lines[count], fixed = TRUE)))
  expect_true(any(grepl('"/traces"', lines, fixed = TRUE)))
  expect_true(any(grepl(
    "reg.finalizer(.BaseNamespaceEnv",
    lines,
    fixed = TRUE
  )))

  expect_error(
    add_base_r_hook(base_loader[-21], "a", "b", "c"),
    "Can't find"
  )
})

test_that("add_base_srcrefs gives functions their source references", {
  src <- withr::local_tempdir()
  dir <- file.path(src, "src", "library", "base", "R")
  dir.create(file.path(dir, "unix"), recursive = TRUE)
  writeLines(
    c(
      "f <- function(x) {",
      "  x + 1",
      "}",
      "g <- h <- function(y) y",
      "k <- function(z) z + 2"
    ),
    file.path(dir, "a.R")
  )
  env <- new.env()
  env$f <- eval(parse(text = "function(x) {\n  x + 1\n}", keep.source = FALSE)[[
    1
  ]])
  env$g <- env$h <- eval(parse(text = "function(y) y", keep.source = FALSE)[[
    1
  ]])
  # Not the same as in the source
  env$k <- eval(parse(text = "function(z) z + 3", keep.source = FALSE)[[1]])
  env$v <- 1

  # `k` differs from the source
  expect_equal(add_base_srcrefs(env, src), "k")

  expect_false(is.null(attr(env$f, "srcref")))
  expect_false(is.null(attr(body(env$f), "srcref")))
  expect_false(is.null(attr(env$h, "srcref")))
  expect_null(attr(env$k, "srcref"))
  expect_equal(
    attr(attr(env$f, "srcref"), "srcfile")$filename,
    file.path(dir, "a.R")
  )
})

test_that("add_base_srcrefs leaves the functions in `exclude` alone", {
  src <- withr::local_tempdir()
  dir <- file.path(src, "src", "library", "base", "R")
  dir.create(file.path(dir, "unix"), recursive = TRUE)
  writeLines("f <- function(x) x", file.path(dir, "a.R"))
  env <- new.env()
  env$f <- eval(parse(text = "function(x) x", keep.source = FALSE)[[1]])

  expect_equal(add_base_srcrefs(env, src, exclude = "f"), character())
  expect_null(attr(env$f, "srcref"))
})

test_that("instrument_base_r_package reports the functions it leaves out", {
  clear_counters()
  on.exit(clear_counters(), add = TRUE)
  old <- the$count_routine
  on.exit(the$count_routine <- old, add = TRUE)
  the$count_routine <- as.symbol(".covr_count")

  src <- srcfilecopy(
    "a.R",
    c(
      "f <- function(x) {",
      "  x + 1",
      "}",
      "g <- function(x) UseMethod('g')",
      "h <- function(x) {",
      "  x + 2",
      "}"
    )
  )
  env <- new.env()
  eval(parse(text = src$lines, srcfile = src, keep.source = TRUE), env)
  # Another name of an excluded function is left out too
  env$i <- env$h

  res <- instrument_base_r_package(env, "pkg", new.env(), exclude = "h")

  expect_setequal(res$excluded, c("g", "h", "i"))
  expect_true(is_traced(env$f))
  expect_false(is_traced(env$h))
  expect_false(is_traced(env$g))
})

test_that("instrument_base_r validates `exclusions`", {
  expect_snapshot(error = TRUE, {
    instrument_base_r(tempdir(), exclusions = c(stats = "pbinom"))
  })
})

test_that("base_r_exclusions lists functions by package", {
  x <- base_r_exclusions()
  expect_named(x, c("base", "methods", "stats"))
  expect_all_true(vapply(x, is.character, logical(1)))
  expect_true("pbinom" %in% x$stats)
})
