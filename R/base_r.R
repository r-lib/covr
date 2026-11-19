# Coverage of the R code of base R itself (the base packages), measured while
# R's own checks (`make check`) or any other process of that build of R runs.
#
# The code is instrumented once, in place, in the installed base packages of a
# build of R (see `instrument_base_r()`): the lazy-load database of each package
# is read into an environment, instrumented and byte-compiled like the code of
# `package_coverage()`, and written next to the original as `<pkg>.covr.rdb`,
# which the loader script of the package is edited to read. The counters call a
# native routine of covr by the symbol `.covr_count`, which the loader script of
# base binds in the base environment, as instrumented base code can't call
# `covr:::` (`:::` is itself a base closure) and loading covr in every process
# would change what the checks do. The loader script of base also registers a
# finalizer that saves the counts when the process exits (see
# `base_r_hook()`), which `base_r_code_coverage()` merges.

# The packages of R with R code, which are in `lib` when they are built.
base_r_packages <- function(lib = R.home("library")) {
  pkgs <- c(
    "base",
    "compiler",
    "graphics",
    "grDevices",
    "grid",
    "methods",
    "parallel",
    "splines",
    "stats",
    "stats4",
    "tcltk",
    "tools",
    "utils"
  )
  pkgs[file.exists(file.path(lib, pkgs, "R", paste0(pkgs, ".rdb")))]
}

base_r_loader <- function(lib, pkg) {
  file.path(lib, pkg, "R", pkg)
}

# The loader script of the package as it was before it was instrumented.
base_r_loader_original <- function(lib, pkg) {
  paste0(base_r_loader(lib, pkg), ".covr-orig")
}

base_r_counters_file <- function(lib) {
  file.path(lib, "base", "R", "covr_counters.rds")
}

#' Instrument the R code of the base packages of R
#'
#' Instruments the installed base packages (base, stats, utils, ...) of the
#' running R, so that the R processes it starts save the counts of the code
#' they run, in `trace_dir` or in the directory of the environment variable
#' `COVERAGE_DIR`. The counts are collected by [base_r_code_coverage()]. This
#' changes the library of the running R: undo it with
#' [uninstrument_base_r()]. Use [base_r_compiled_coverage()] for its C and
#' Fortran code.
#'
#' Functions of base have no source references in a build of R, so they are
#' read from the source files in `source_dir`, which are used for the functions
#' whose code is the same as the installed one. Functions whose body is a
#' constant or a call to `UseMethod()` are not instrumented, as code inspects
#' them.
#'
#' @section Requirements:
#' * Build R from source, with the environment variable
#'   `R_KEEP_PKG_SOURCE=yes` set so that the packages have source references.
#' * Run `instrument_base_r()` with the R that is instrumented, e.g. the
#'   `bin/Rscript` of a build that is not installed, as the byte-code in the
#'   databases depends on the version of R. covr has to be installed in a
#'   library this R can use, e.g. with `R_LIBS`.
#' * covr must stay installed at the same path while R is instrumented, as
#'   instrumented processes load the native code of covr from there.
#' * This is only supported on Unix-alikes: forked processes of
#'   `parallel::mclapply()` save their counts as they exit.
#'
#' @section Example workflow:
#' ```r
#' # With R built from `R-devel` in `build`, and covr installed in `lib`, run
#' # this with `R_LIBS=lib build/bin/Rscript`:
#' library(covr)
#' instrument_base_r("R-devel", lib = "build/library", trace_dir = "traces")
#'
#' # Then run the checks, saving the counts in `traces`:
#' #   COVERAGE_DIR=traces make check
#'
#' cov <- base_r_code_coverage("traces", "R-devel")
#' report(cov)
#'
#' # Restore R, with the same R as above
#' uninstrument_base_r(lib = "build/library")
#' ```
#'
#' @param source_dir The directory of the source of R, that R was built from.
#' @param lib The library of the base packages of R.
#' @param trace_dir The directory the counts are saved in, if the environment
#'   variable `COVERAGE_DIR` is not set when a process of R exits.
#' @param packages The packages to instrument.
#' @return A list, invisibly, with the number of closures in base and how many
#'   of them have source references (`base_functions`, `base_srcrefs`), the
#'   functions that could not be byte-compiled (`uncompiled`) and the packages
#'   that were instrumented.
#' @family base R coverage
#' @export
instrument_base_r <- function(
  source_dir,
  lib = R.home("library"),
  trace_dir = file.path(dirname(lib), "covr-traces"),
  packages = base_r_packages(lib)
) {
  source_dir <- normalize_path(source_dir)
  if (!dir.exists(source_dir)) {
    covr_abort("Can't find the source directory {.path {source_dir}}.")
  }
  lib <- normalize_path(lib)
  trace_dir <- normalize_path(trace_dir)
  if (
    !all(file.exists(file.path(lib, packages, "R", paste0(packages, ".rdb"))))
  ) {
    covr_abort(
      "Can't find the installed packages {.val {packages}} in {.path {lib}}."
    )
  }
  done <- file.exists(base_r_loader_original(lib, packages))
  if (any(done)) {
    covr_abort(
      c(
        "{.pkg {packages[done]}} {?is/are} already instrumented.",
        i = "Use {.fn uninstrument_base_r} first."
      )
    )
  }
  dll <- getLoadedDLLs()[["covr"]]
  if (is.null(dll)) {
    covr_abort("The native code of covr is not loaded.")
  }
  dll_path <- normalize_path(dll[["path"]])

  # Keys have the full names of files, as many of them have the same name in
  # different packages
  old_routine <- the$count_routine
  old_options <- options(
    covr.record_tests = FALSE,
    covr.full_traversal = FALSE,
    covr.branch_coverage = FALSE
  )
  on.exit(
    {
      the$count_routine <- old_routine
      options(old_options)
    },
    add = TRUE
  )
  the$count_routine <- as.symbol(".covr_count")

  counters <- new.env(parent = emptyenv())
  info <- list(
    base_functions = 0L,
    base_srcrefs = 0L,
    uncompiled = character(),
    packages = character()
  )
  written <- character()
  on.exit(unlink(written, expand = FALSE), add = TRUE)

  for (pkg in packages) {
    base <- file.path(lib, pkg, "R", pkg)
    env <- new.env(hash = TRUE, parent = emptyenv())
    lazyLoad(base, env)
    if (pkg == "base") {
      info[c("base_functions", "base_srcrefs")] <- add_base_srcrefs(
        env,
        source_dir
      )
    }
    uncompiled <- instrument_base_r_package(env, pkg, counters)
    force_srcfiles(env)
    new_base <- paste0(base, ".covr")
    written <- c(written, paste0(new_base, c(".rdb", ".rdx")))
    make_lazy_load_db <- get("makeLazyLoadDB", envir = asNamespace("tools"))
    make_lazy_load_db(
      env,
      new_base,
      compress = readRDS(paste0(base, ".rdx"))$compressed
    )
    info$uncompiled <- c(info$uncompiled, uncompiled)
    info$packages <- c(info$packages, pkg)
  }

  counters_file <- base_r_counters_file(lib)
  saveRDS(portable_srcfiles(counters), counters_file)
  written <- c(written, counters_file)
  dir.create(trace_dir, showWarnings = FALSE, recursive = TRUE)

  # The loaders are changed last, so that R is as it was if anything fails.
  for (pkg in packages) {
    loader <- base_r_loader(lib, pkg)
    file.copy(loader, base_r_loader_original(lib, pkg))
    lines <- readLines(loader)
    lines <- if (pkg == "base") {
      add_base_r_hook(lines, dll_path, counters_file, trace_dir)
    } else {
      add_pkg_r_hook(lines)
    }
    writeLines(lines, loader)
  }
  written <- character()

  invisible(info)
}

# Functions whose code R's tests inspect, so they fail if it has counters:
# `reg-tests-1c.R` looks up the name of the native routine in
# `body(pbinom)[[2]]`, `reg-tests-1d.R` compares `dump()` and `dput()` of
# `simplify2array()`, which warn that the deparse of the counters may be
# incomplete, `rematchDefinition()` builds the body of rematched S4 methods from
# its own code, which `isRematched()` (`reg-tests-1e.R`) checks, and the tests
# of compiler check that the base functions it inlines are simple `.Internal()`
# calls. The compiler inlines these in byte-compiled callers, so they are rarely
# called anyway.
base_r_uninstrumented <- function(pkg) {
  switch(
    pkg,
    base = c(
      "simplify2array",
      get("safeBaseInternals", envir = asNamespace("compiler"))
    ),
    methods = "rematchDefinition",
    stats = "pbinom",
    character()
  )
}

# Instrument the functions in `env`, which holds the code of `pkg`, and
# byte-compile them in place. Adds the counters to `counters`, an environment.
# Returns the names of the functions that couldn't be byte-compiled.
instrument_base_r_package <- function(env, pkg, counters) {
  # Some code compares the body of functions with what it expects, as methods
  # does for the `test` of the extensions of S4 classes, `function(object)
  # TRUE`, and `isS3stdGeneric()` does for generic functions, which are
  # `function(x, ...) UseMethod("f")`. Functions like that have no code to
  # cover, so they are left as they are, as are the functions whose code R's
  # own tests inspect (see `base_r_uninstrumented()`).
  uninstrumented <- base_r_uninstrumented(pkg)
  fixed <- list()
  for (name in ls(env, all.names = TRUE)) {
    fun <- env[[name]]
    if (
      is.function(fun) &&
        !is.primitive(fun) &&
        (is_fixed_body(body(fun)) || name %in% uninstrumented)
    ) {
      fixed[[name]] <- fun
      rm(list = name, envir = env)
    }
  }
  trace_environment(env)
  list2env(fixed, env)
  for (key in ls(.counters, all.names = TRUE)) {
    counters[[key]] <- .counters[[key]]
  }
  compiled <- character()
  for (r in the$replacements) {
    compiled[[length(compiled) + 1L]] <- compile_in_place_checked(r)
  }
  if (pkg == "parallel") {
    patch_parallel_forks(env)
  }
  if (pkg == "base") {
    drop_parse_data(counters)
    drop_function_srcrefs(env)
  }
  compiled[!is.na(compiled)]
}

# Source files of base are read when it is instrumented, with their parse data,
# which is not needed to run it and is left out of the database.
drop_parse_data <- function(counters) {
  for (key in ls(counters, all.names = TRUE)) {
    srcfile <- attr(counters[[key]]$srcref, "srcfile")
    if (
      is.environment(srcfile) && exists("parseData", srcfile, inherits = FALSE)
    ) {
      rm("parseData", envir = srcfile)
    }
  }
}

# The source files of code read from a lazy-load database have promises to read
# their lines, whose environment is the frame of the function that read the
# database, which references all that it read. Writing them unforced, as
# `makeLazyLoadDB()` does, would write all of that too, e.g. all of the code of
# the package, or of covr for code that covr adds. Forced promises only keep
# their value. The source files are found as `makeLazyLoadDB()` finds them, in
# all the objects in `env`, e.g. also in the methods tables of S4 generics,
# which hold the methods of other packages.
force_srcfiles <- function(env) {
  done <- new.env(parent = emptyenv())
  invisible(serialize(
    as.list(env, all.names = TRUE),
    NULL,
    refhook = function(x) {
      if (inherits(x, "srcfile") && is.null(done[[address(x)]])) {
        done[[address(x)]] <- TRUE
        for (name in ls(x, all.names = TRUE)) {
          get(name, envir = x)
        }
      }
      NULL
    }
  ))
}

# Whether the body of a function is a constant, or a call to `UseMethod()`,
# which can be in braces.
is_fixed_body <- function(x) {
  if (is.call(x) && identical(x[[1L]], as.name("{")) && length(x) == 2L) {
    x <- x[[2L]]
  }
  is.null(x) ||
    is.atomic(x) ||
    (is.call(x) && identical(x[[1L]], as.name("UseMethod")))
}

# The functions of base have no source references when R is built, so tests that
# print them or compare their attributes would fail with them. Their code keeps
# the source references of its expressions, which is what the counters use.
drop_function_srcrefs <- function(env) {
  for (name in ls(env, all.names = TRUE)) {
    fun <- env[[name]]
    if (is.function(fun) && !is.null(attr(fun, "srcref"))) {
      attr(fun, "srcref") <- NULL
      assign(name, fun, envir = env)
    }
  }
}

# Byte-compile the instrumented function of the replacement `r`, returning `NA`,
# or the name of the function if that failed.
compile_in_place_checked <- function(r) {
  fun <- r$target_value
  if (!is.function(fun) || is.primitive(fun)) {
    return(NA_character_)
  }
  compiled <- tryCatch(compiler::cmpfun(fun), error = function(e) NULL)
  if (!is.function(compiled)) {
    return(as.character(r$name))
  }
  .Call(covr_reassign_function, fun, compiled)
  NA_character_
}

# The functions of `env`, the code of base, with the source references of the
# functions that are the same in the source files in `source_dir`, which are
# found by parsing the files in the order they are put together to make the
# code of base. Functions that are not instrumented (see
# `base_r_uninstrumented()`) are left without them, as in R, since tests deparse
# them. Returns the number of functions and of functions with source
# references.
add_base_srcrefs <- function(env, source_dir) {
  dir <- file.path(source_dir, "src", "library", "base", "R")
  files <- c(
    sort(
      list.files(dir, pattern = "[.]R$", full.names = TRUE),
      method = "radix"
    ),
    sort(
      list.files(file.path(dir, "unix"), pattern = "[.]R$", full.names = TRUE),
      method = "radix"
    )
  )
  if (length(files) == 0L) {
    covr_abort("Can't find the source of base in {.path {dir}}.")
  }
  names <- ls(env, all.names = TRUE)
  is_closure <- vlapply(names, function(name) {
    is.function(env[[name]]) && !is.primitive(env[[name]])
  })
  with_srcref <- character()
  for (file in files) {
    exprs <- parse(file, keep.source = TRUE, encoding = "UTF-8")
    for (expr in exprs) {
      defined <- function_definition(expr)
      if (is.null(defined)) {
        next
      }
      for (name in setdiff(
        intersect(defined$names, names[is_closure]),
        base_r_uninstrumented("base")
      )) {
        new <- eval(defined$fun, baseenv())
        old <- env[[name]]
        if (same_function(old, new)) {
          environment(new) <- environment(old)
          assign(name, new, envir = env)
          with_srcref <- union(with_srcref, name)
        }
      }
    }
  }
  c(sum(is_closure), length(with_srcref))
}

# Whether the functions have the same code, whatever their source references,
# which are in the attributes of every `{` call, and not just of the function.
# `identical()` ignores only the `srcref` attribute of these, not their `srcfile`
# and `wholeSrcref`, so the code is compared as it is deparsed.
same_function <- function(x, y) {
  attr(x, "srcref") <- NULL
  attr(y, "srcref") <- NULL
  identical(deparse(x, width.cutoff = 500L), deparse(y, width.cutoff = 500L))
}

# The names and the function of a top-level `name <- function(...) ...`, which
# can be chained as in `a <- b <- function(...) ...`, or `NULL`.
function_definition <- function(expr) {
  names <- character()
  while (
    is.call(expr) &&
      length(expr) == 3L &&
      (identical(expr[[1L]], as.name("<-")) ||
        identical(expr[[1L]], as.name("="))) &&
      (is.name(expr[[2L]]) || is.character(expr[[2L]]))
  ) {
    names <- c(names, as.character(expr[[2L]]))
    expr <- expr[[3L]]
  }
  if (
    length(names) > 0L &&
      is.call(expr) &&
      identical(expr[[1L]], as.name("function"))
  ) {
    list(names = names, fun = expr)
  }
}

# Processes forked by `mclapply()` and `mcparallel()` exit without running
# finalizers or exit handlers, so they save their counts when they exit, and
# write the counts of gcov if R was built with `--coverage`. After the fork
# they start with no counts, as the counts the parent had when it forked are
# the parent's (gcov does this itself). These are statements added to the
# instrumented functions of `parallel`, which are replaced in `env` by
# byte-compiled copies.
patch_parallel_forks <- function(env) {
  # The statements are made without source references, which would be those of
  # covr's code
  insert <- function(fun, after, statements) {
    calls <- append(as.list(body(fun)), statements, after = after)
    body(fun) <- as.call(calls)
    compiler::cmpfun(fun)
  }
  if (is.function(env$mcfork)) {
    env$mcfork <- insert(
      env$mcfork,
      2L,
      # The native routines are bound by the loader of base, so they are not
      # written as `.Call(.covr_zero)`, which R CMD check looks up in covr.
      list(call("if", quote(!r[1L]), call(".Call", as.name(".covr_zero"))))
    )
  }
  if (is.function(env$mcexit)) {
    env$mcexit <- insert(
      env$mcexit,
      1L,
      list(quote(.covr_save()), call(".Call", as.name(".covr_gcov_dump")))
    )
  }
  invisible()
}

# Read the instrumented code of a package other than base, instead of the
# installed code.
add_pkg_r_hook <- function(lines) {
  db_line <- grep(
    'dbbase <- file.path(info$libname, pkg, "R", pkg)',
    lines,
    fixed = TRUE
  )
  if (length(db_line) != 1L) {
    covr_abort("Can't find where the loader script reads the package.")
  }
  lines[db_line] <- sub(
    '"R", pkg)',
    '"R", paste0(pkg, ".covr"))',
    lines[db_line],
    fixed = TRUE
  )
  lines
}

# The loader script of base, with the instrumented code read in place of the
# installed code, and the code that makes it count the code that runs (see
# `base_r_hook()`) after it has read the code.
add_base_r_hook <- function(lines, dll_path, counters_file, trace_dir) {
  lines <- add_lazy_environments(lines)
  db_line <- grep('"base", sep= .Platform$file.sep)', lines, fixed = TRUE)
  end_line <- grep(
    "}), .Internal(new.env(FALSE, baseenv(), 29L)), baseenv()))",
    lines,
    fixed = TRUE
  )
  if (length(db_line) != 1L || length(end_line) != 1L || end_line < db_line) {
    covr_abort("Can't find where the loader script of base reads the code.")
  }
  lines[db_line] <- sub(
    '"base", sep=',
    '"base.covr", sep=',
    lines[db_line],
    fixed = TRUE
  )
  append(lines, base_r_hook(dll_path, counters_file, trace_dir), end_line)
}

# The loader script of base only reads the environments that were written the
# way `makeLazyLoadDB()` of base did, but the database of the instrumented code
# has the source references of its functions, whose source files are
# environments with bindings that are read when they are used, as
# `lazyLoad()` reads them.
add_lazy_environments <- function(lines) {
  key_line <- grep("key <- env[[n]]", lines, fixed = TRUE)
  data_line <- grep(
    "data <- lazyLoadDBfetch(key, datafile, compressed, envhook)",
    lines,
    fixed = TRUE
  )
  attributes_line <- grep(
    "attributes(e) <- data$attributes",
    lines,
    fixed = TRUE
  )
  if (
    length(key_line) != 1L ||
      length(data_line) != 1L ||
      length(attributes_line) != 1L
  ) {
    covr_abort("Can't find where the loader script of base reads environments.")
  }
  lines[data_line] <- sub("(key,", "(ekey,", lines[data_line], fixed = TRUE)
  lines <- append(
    lines,
    c(
      "            if (is.list(key)) {",
      "                lazy <- quote(lazyLoadDBfetch(KEY, datafile, compressed, envhook))",
      "                .Internal(makeLazy(names(key$lazyKeys), key$lazyKeys, lazy, this, e))",
      "            }"
    ),
    attributes_line
  )
  append(
    lines,
    "            ekey <- if (is.list(key)) key$eagerKey else key",
    key_line
  )
}

# The lines that are added to the loader script of base. Instrumented code
# can't count until `.covr_count` is bound, so until then these only use
# primitives and `.Internal()`; base is not locked while it is loaded.
#
# A process saves the counts it has when it exits (`.covr_save()`), or when a
# forked process exits (see `patch_parallel_forks()`), by the name that
# `merge_traces()` reads. The counts are taken first, so what the function itself
# runs is not counted, and nothing is printed or signaled if it fails.
base_r_hook <- function(dll_path, counters_file, trace_dir) {
  quote_string <- function(x) encodeString(x, quote = '"')
  symbol <- function(name) {
    paste0(
      '.Internal(getSymbolInfo("',
      name,
      '", .Internal(dyn.load(',
      quote_string(dll_path),
      ', TRUE, TRUE, ""))[["info"]], FALSE))[["address"]]'
    )
  }
  c(
    "",
    "## covr: count the code of base R that runs, see covr:::instrument_base_r()",
    paste0(".covr_count <- ", symbol("covr_count_auto")),
    paste0(".covr_take <- ", symbol("covr_counter_take")),
    paste0(".covr_zero <- ", symbol("covr_counter_reset")),
    paste0(".covr_gcov_dump <- ", symbol("covr_gcov_dump")),
    ".covr_save <- function() {",
    "    counts <- .Call(.covr_take)",
    "    if (length(counts) > 0L) {",
    "        tryCatch({",
    '            dir <- Sys.getenv("COVERAGE_DIR")',
    paste0("            if (!nzchar(dir)) dir <- ", quote_string(trace_dir)),
    "            if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)",
    '            tmp <- tempfile(".covr_tmp_", dir)',
    "            on.exit(unlink(tmp))",
    "            saveRDS(structure(list(counters_file = ",
    paste0("                ", quote_string(counters_file), ","),
    "                counts = counts, counters = list()),",
    '                class = "covr_counts"), tmp)',
    '            file.rename(tmp, tempfile("covr_trace_", dir))',
    "        }, error = function(e) NULL, warning = function(w) NULL)",
    "    }",
    "    .Call(.covr_zero)",
    "    invisible()",
    "}",
    "invisible(.Internal(reg.finalizer(.BaseNamespaceEnv, function(e) .covr_save(), TRUE)))"
  )
}

#' Restore the base packages that were instrumented
#'
#' Undoes [instrument_base_r()]: the loader scripts of the packages are
#' restored and the instrumented code is removed. Run it with the same R as
#' `instrument_base_r()`, after [base_r_code_coverage()], which reads the
#' counters that this removes.
#'
#' @inheritParams instrument_base_r
#' @return `NULL`, invisibly.
#' @family base R coverage
#' @export
uninstrument_base_r <- function(
  lib = R.home("library"),
  packages = base_r_packages(lib)
) {
  lib <- normalize_path(lib)
  if (!dir.exists(lib)) {
    covr_abort("Can't find the library {.path {lib}}.")
  }
  for (pkg in packages) {
    original <- base_r_loader_original(lib, pkg)
    if (file.exists(original)) {
      file.copy(original, base_r_loader(lib, pkg), overwrite = TRUE)
      unlink(original, expand = FALSE)
    }
    unlink(
      paste0(base_r_loader(lib, pkg), c(".covr.rdb", ".covr.rdx")),
      expand = FALSE
    )
  }
  unlink(base_r_counters_file(lib), expand = FALSE)
  invisible()
}

#' Coverage of the R code of base R
#'
#' Merges the counts that the processes of an instrumented R (see
#' [instrument_base_r()]) saved in `trace_dir`.
#'
#' @param trace_dir The directory the processes saved their counts in.
#' @param source_dir The directory of the source of R, which the files in the
#'   coverage are in.
#' @return A coverage object. File names are absolute paths in `source_dir`.
#' @family base R coverage
#' @export
base_r_code_coverage <- function(trace_dir, source_dir) {
  trace_dir <- normalize_path(trace_dir)
  source_dir <- normalize_path(source_dir)
  if (!dir.exists(trace_dir)) {
    covr_abort("Can't find the trace directory {.path {trace_dir}}.")
  }
  if (!dir.exists(source_dir)) {
    covr_abort("Can't find the source directory {.path {source_dir}}.")
  }
  traces <- merge_traces(trace_dir)
  normalize_srcfile_names(traces)
  as_coverage(
    traces,
    package = list(package = "R", path = source_dir),
    root = source_dir
  )
}

# The file names in the source references of the base packages are the paths
# R was configured with, e.g. `build/../R-devel/src/library/stats/R/lm.R` for a
# build out of the source tree, so they are normalized to be under the source
# directory.
normalize_srcfile_names <- function(traces) {
  for (trace in traces) {
    srcfile <- attr(trace$srcref, "srcfile")
    if (is.environment(srcfile) && is.character(srcfile$filename)) {
      srcfile$filename <- normalize_path(srcfile$filename)
    }
  }
  invisible()
}
