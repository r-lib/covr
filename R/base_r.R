# Coverage of the R code of base R itself (the base packages), measured while
# R's own checks (`make check`) or any other process of that build of R runs.
#
# The code is instrumented once, in place, in the installed base packages of a
# build of R (see `instrument_base_r()`): the lazy-load database of each package
# is read into an environment, instrumented and byte-compiled like the code of
# `package_coverage()`, and written next to the original as `<pkg>.covr.rdb`,
# which the loader script of the package is edited to read. The counters call a
# native routine of covr as `.covr$call(.covr$count, key)`, which the loader
# script of base binds in the base environment, as instrumented base code can't call
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
#' `COVR_TRACE_DIR`. The counts are collected by [base_r_code_coverage()]. This
#' changes the library of the running R: undo it with
#' [uninstrument_base_r()]. Use [base_r_compiled_coverage()] for its C and
#' Fortran code.
#'
#' Functions of base have no source references in a build of R, so they are
#' read from the source files in `source_dir`, which are used for the functions
#' whose code is the same as the installed one. Functions without source
#' references are not measured.
#'
#' Some functions are not instrumented, so they are not in the coverage, not
#' even as code that never ran: the functions in `exclusions` (by default
#' [base_r_exclusions()], those whose code R's own checks inspect), and
#' functions whose body is a constant or a call to `UseMethod()`, which have no
#' code to cover and whose bodies code also compares. The default arguments of
#' functions are not traced either, as `R CMD check` compares them with the
#' documentation.
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
#' #   COVR_TRACE_DIR=traces make check
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
#'   variable `COVR_TRACE_DIR` is not set when a process of R exits.
#' @param packages The packages to instrument, which must include base, whose
#'   loader counts the code that runs and saves the counts.
#' @param cores The number of packages to instrument in parallel, in forked
#'   processes. Instrumenting byte-compiles the code, which takes long in a
#'   build of R without optimization, e.g. one built for the coverage of its
#'   compiled code.
#' @param exclusions A named list of the functions not to instrument, by
#'   package, e.g. `list(stats = "pbinom")`. Use `NULL` to instrument all of
#'   them, which makes some of R's checks fail.
#' @return A list, invisibly, with:
#'   * `packages`: the packages that were instrumented.
#'   * `excluded`: the functions that were not instrumented, by package: those
#'     in `exclusions` and those with a constant or `UseMethod()` body.
#'   * `no_srcref`: the functions of base that are not measured, as their code
#'     differs from the source files, e.g. as it was created by other code.
#'   * `uncompiled`: the functions that could not be byte-compiled.
#' @seealso The article [Coverage of R itself](https://covr.r-lib.org/articles/base-r.html).
#' @family base R coverage
#' @export
instrument_base_r <- function(
  source_dir,
  lib = R.home("library"),
  trace_dir = file.path(dirname(lib), "covr-traces"),
  packages = base_r_packages(lib),
  exclusions = base_r_exclusions(),
  cores = getOption("Ncpus", 1L)
) {
  if (
    !is.null(exclusions) &&
      (!is.list(exclusions) ||
        is.null(names(exclusions)) ||
        !all(vlapply(exclusions, is.character)))
  ) {
    covr_abort(
      "{.arg exclusions} must be a named list of function names, or {.code NULL}."
    )
  }
  source_dir <- normalize_path(source_dir)
  if (!dir.exists(source_dir)) {
    covr_abort("Can't find the source directory {.path {source_dir}}.")
  }
  lib <- normalize_path(lib)
  # The hook in the loader of base binds what the instrumented code of the other
  # packages counts with, and saves the counts.
  if (!"base" %in% packages) {
    covr_abort("{.arg packages} must include {.pkg base}.")
  }
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
  old_count_call <- the$count_call
  old_trace_formals <- the$trace_formals
  old_options <- options(
    covr.record_tests = FALSE,
    covr.full_traversal = FALSE,
    covr.branch_coverage = FALSE
  )
  on.exit(
    {
      the$count_routine <- old_routine
      the$count_call <- old_count_call
      the$trace_formals <- old_trace_formals
      options(old_options)
    },
    add = TRUE
  )
  the$count_routine <- quote(.covr$count)
  the$count_call <- quote(.covr$call)
  the$trace_formals <- FALSE

  # Each package is instrumented on its own, the largest first, so that with
  # several `cores` the last ones to start are the quickest.
  sizes <- file.size(file.path(lib, packages, "R", paste0(packages, ".rdb")))
  order <- packages[order(sizes, decreasing = TRUE)]
  bases <- file.path(lib, order, "R", order)
  written <- as.vector(outer(paste0(bases, ".covr"), c(".rdb", ".rdx"), paste0))
  on.exit(unlink(written, expand = FALSE), add = TRUE)

  instrument_one <- function(pkg) {
    instrument_base_r_one(pkg, lib, source_dir, exclusions[[pkg]])
  }
  results <- if (cores > 1L && length(order) > 1L) {
    parallel::mclapply(
      order,
      instrument_one,
      mc.cores = cores,
      mc.preschedule = FALSE
    )
  } else {
    lapply(order, instrument_one)
  }
  names(results) <- order
  # A worker that was killed, e.g. when it ran out of memory, gives `NULL`
  # rather than an error.
  failed <- vlapply(results, function(x) {
    inherits(x, "try-error") || !is.list(x)
  })
  if (any(failed)) {
    reason <- results[failed][[1]]
    covr_abort(c(
      "Can't instrument {.pkg {order[failed]}}.",
      x = if (inherits(reason, "try-error")) {
        conditionMessage(attr(reason, "condition"))
      } else {
        "The process instrumenting it was killed."
      }
    ))
  }
  results <- results[packages]

  counters <- new.env(parent = emptyenv())
  for (res in results) {
    list2env(res$counters, counters)
  }
  info <- list(
    packages = packages,
    excluded = lapply(results, `[[`, "excluded"),
    no_srcref = results[["base"]]$no_srcref %||% character(),
    uncompiled = unlist(lapply(results, `[[`, "uncompiled"), use.names = FALSE)
  )

  # The directory is created first, so that a relative path is made absolute:
  # processes save their counts there, whatever their working directory.
  dir.create(trace_dir, showWarnings = FALSE, recursive = TRUE)
  trace_dir <- normalize_path(trace_dir)
  counters_file <- base_r_counters_file(lib)
  saveRDS(portable_srcfiles(counters), counters_file)
  written <- c(written, counters_file)

  # The running R can't run the instrumented code, which counts with bindings
  # that only the loader of base adds, so if it is the R being instrumented it
  # loads the packages it hasn't loaded yet before their loaders are changed.
  if (identical(lib, normalize_path(.Library))) {
    for (pkg in packages) {
      suppressWarnings(requireNamespace(pkg, quietly = TRUE))
    }
  }

  # The loaders are changed last, so that R is as it was if anything fails:
  # all the new loaders are made before any is changed, and the ones that were
  # changed are restored if writing another one fails.
  loaders <- lapply(packages, function(pkg) {
    lines <- readLines(base_r_loader(lib, pkg))
    if (pkg == "base") {
      add_base_r_hook(lines, dll_path, counters_file, trace_dir)
    } else {
      add_pkg_r_hook(lines)
    }
  })
  changed <- character()
  tryCatch(
    for (i in seq_along(packages)) {
      pkg <- packages[[i]]
      if (
        !file.copy(base_r_loader(lib, pkg), base_r_loader_original(lib, pkg))
      ) {
        covr_abort("Can't back up the loader of {.pkg {pkg}}.")
      }
      changed <- c(changed, pkg)
      writeLines(loaders[[i]], base_r_loader(lib, pkg))
    },
    error = function(e) {
      restore_base_r_loaders(lib, changed)
      stop(e)
    }
  )
  written <- character()

  invisible(info)
}

# Instrument the installed package `pkg` in `lib`, writing its instrumented
# code next to the installed one. Run in a forked process with several cores,
# so it returns what the main process needs: the functions that were left out
# (see `instrument_base_r_package()`), the functions of base without source
# references, and the counters, with copies of their srcfiles that can be sent
# back.
instrument_base_r_one <- function(pkg, lib, source_dir, exclude) {
  base <- file.path(lib, pkg, "R", pkg)
  env <- new.env(hash = TRUE, parent = emptyenv())
  lazyLoad(base, env)
  no_srcref <- if (pkg == "base") {
    add_base_srcrefs(env, source_dir, exclude = exclude)
  }
  counters <- new.env(parent = emptyenv())
  res <- instrument_base_r_package(env, pkg, counters, exclude = exclude)
  force_srcfiles(env)
  make_lazy_load_db <- get("makeLazyLoadDB", envir = asNamespace("tools"))
  make_lazy_load_db(
    env,
    paste0(base, ".covr"),
    compress = readRDS(paste0(base, ".rdx"))$compressed
  )
  list(
    excluded = res$excluded,
    uncompiled = res$uncompiled,
    no_srcref = no_srcref,
    counters = portable_srcfiles(as.list(counters, all.names = TRUE))
  )
}

#' The functions that are not instrumented by default
#'
#' The functions of R that [instrument_base_r()] leaves as they are by default,
#' as R's own checks (`make check-all`) inspect their code, so they fail if it
#' counts what runs:
#'
#' * `stats::pbinom()`: a regression test reads the name of its native routine
#'   from its body.
#' * `base::simplify2array()`: a regression test compares its `dump()` and
#'   `dput()`.
#' * `methods:::rematchDefinition()`: it builds the body of rematched S4
#'   methods from its own code, which `isRematched()` checks.
#' * The functions of base that the byte-code compiler inlines
#'   (`compiler:::safeBaseInternals`), whose tests check that they only call
#'   `.Internal()`. As they are inlined, they rarely run anyway.
#' * The internal generics of base (`.internalGenerics`), which the tests of
#'   tools check call `.Internal()`.
#'
#' @return A named list of function names, by package.
#' @family base R coverage
#' @export
#' @examples
#' str(base_r_exclusions())
#'
#' # Also leave out lm()
#' exclusions <- base_r_exclusions()
#' exclusions$stats <- c(exclusions$stats, "lm")
base_r_exclusions <- function() {
  list(
    base = c(
      "simplify2array",
      get("safeBaseInternals", envir = asNamespace("compiler")),
      # Not in R 4.2
      get0(".internalGenerics", envir = baseenv(), ifnotfound = character())
    ),
    methods = "rematchDefinition",
    stats = "pbinom"
  )
}

# Instrument the functions in `env`, which holds the code of `pkg`, except
# those in `exclude`, and byte-compile them in place. Adds the counters to
# `counters`, an environment. Returns the names of the functions that were not
# instrumented (`excluded`) and that couldn't be byte-compiled (`uncompiled`).
instrument_base_r_package <- function(env, pkg, counters, exclude = NULL) {
  # Some code compares the body of functions with what it expects, as methods
  # does for the `test` of the extensions of S4 classes, `function(object)
  # TRUE`, and `isS3stdGeneric()` does for generic functions, which are
  # `function(x, ...) UseMethod("f")`. Functions like that have no code to
  # cover, so they are left as they are, as are the functions in `exclude`.
  # Functions are instrumented in place, so the other names of the same
  # function, e.g. `as.data.frame.integer <- as.data.frame.vector`, are left
  # out too.
  is_closure <- function(x) is.function(x) && !is.primitive(x)
  names <- ls(env, all.names = TRUE)
  skip <- vlapply(names, function(name) {
    fun <- env[[name]]
    is_closure(fun) && (is_fixed_body(body(fun)) || name %in% exclude)
  })
  skipped <- vcapply(mget(names[skip], envir = env), address)
  skip <- skip |
    vlapply(names, function(name) {
      fun <- env[[name]]
      is_closure(fun) && address(fun) %in% skipped
    })
  fixed <- mget(names[skip], envir = env)
  rm(list = names[skip], envir = env)
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
  list(excluded = names(fixed), uncompiled = compiled[!is.na(compiled)])
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
# code of base. Functions in `exclude` are left without them, as in R, since
# tests deparse them. Returns the names of the other functions that have no
# source references.
add_base_srcrefs <- function(env, source_dir, exclude = NULL) {
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
        exclude
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
  setdiff(names[is_closure], c(with_srcref, exclude))
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
      # `.covr$call` is `.Call` (see `base_r_hook()`), so that neither covr's
      # R CMD check nor that of parallel looks up the routine.
      list(call("if", quote(!r[1L]), quote(.covr$call(.covr$zero))))
    )
  }
  if (is.function(env$mcexit)) {
    env$mcexit <- insert(
      env$mcexit,
      1L,
      list(
        quote(.covr$save()),
        quote(.covr$call(.covr$gcov_dump))
      )
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
# can't count until `.covr` is bound, so until then these only use
# primitives and `.Internal()`; base is not locked while it is loaded.
#
# A process saves the counts it has when it exits (`.covr$save()`), or when a
# forked process exits (see `patch_parallel_forks()`), by the name that
# `merge_traces()` reads. The counts are taken first, so what the function itself
# runs is not counted, and nothing is printed or signaled if it fails. It is in
# a list rather than a function in base, which `R CMD check` of base would
# report as undocumented.
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
    "## Everything is in one list, as R's checks look at the functions in base:",
    "## the counters call `.Call` by another name, as R CMD check would report",
    "## each of them as calling a routine that isn't base's, and the tests",
    "## check that the primitives in base are the known ones.",
    ".covr <- list(",
    "    call = .Call,",
    paste0("    count = ", symbol("covr_count_auto"), ","),
    paste0("    take = ", symbol("covr_counter_take"), ","),
    paste0("    zero = ", symbol("covr_counter_reset"), ","),
    paste0("    gcov_dump = ", symbol("covr_gcov_dump"), ","),
    "    save = function() {",
    "        counts <- .Call(.covr$take)",
    "        if (length(counts) > 0L) {",
    "            tryCatch({",
    '                dir <- Sys.getenv("COVR_TRACE_DIR")',
    paste0(
      "                if (!nzchar(dir)) dir <- ",
      quote_string(trace_dir)
    ),
    "                if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)",
    '                tmp <- tempfile(".covr_tmp_", dir)',
    "                on.exit(unlink(tmp))",
    "                saveRDS(structure(list(counters_file = ",
    paste0("                    ", quote_string(counters_file), ","),
    "                    counts = counts, counters = list()),",
    '                    class = "covr_counts"), tmp)',
    '                file.rename(tmp, tempfile("covr_trace_", dir))',
    "            }, error = function(e) NULL, warning = function(w) NULL)",
    "        }",
    "        .Call(.covr$zero)",
    "        invisible()",
    "    }",
    ")",
    "invisible(.Internal(reg.finalizer(.BaseNamespaceEnv, function(e) .covr$save(), TRUE)))"
  )
}

#' Restore the base packages that were instrumented
#'
#' Undoes [instrument_base_r()]: the loader scripts of the packages are
#' restored and the instrumented code is removed. Run it with the same R as
#' `instrument_base_r()`, after [base_r_code_coverage()], which reads the
#' counters that this removes once no package is instrumented. base can only
#' be restored with all the other instrumented packages.
#'
#' @param packages The packages to restore.
#'
#' @inheritParams instrument_base_r
#' @return `NULL`, invisibly.
#' @seealso The article [Coverage of R itself](https://covr.r-lib.org/articles/base-r.html).
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
  instrumented <- function() {
    pkgs <- base_r_packages(lib)
    pkgs[file.exists(base_r_loader_original(lib, pkgs))]
  }
  # The other packages count with the bindings of the loader of base
  if ("base" %in% packages && length(setdiff(instrumented(), packages))) {
    covr_abort(c(
      "Can't restore {.pkg base} while other packages are instrumented.",
      i = "Restore {.pkg {setdiff(instrumented(), packages)}} too."
    ))
  }
  # The running R may still read the instrumented code of the namespaces it has
  # loaded, through promises to read it when it is first used, so these are
  # read before it is removed.
  if (identical(lib, normalize_path(.Library))) {
    for (pkg in intersect(packages, loadedNamespaces())) {
      invisible(as.list(asNamespace(pkg), all.names = TRUE))
    }
  }
  restore_base_r_loaders(lib, packages)
  for (pkg in packages) {
    unlink(
      paste0(base_r_loader(lib, pkg), c(".covr.rdb", ".covr.rdx")),
      expand = FALSE
    )
  }
  # The counters are used by the packages that are still instrumented
  if (!length(instrumented())) {
    unlink(base_r_counters_file(lib), expand = FALSE)
  }
  invisible()
}

# Restore the loaders of `packages` from their backups, which are only removed
# once they are restored, so that a package whose loader can't be restored can
# still be restored later. base is restored last, as the others count with the
# bindings of its instrumented loader: it stays instrumented if another fails.
restore_base_r_loaders <- function(lib, packages) {
  packages <- c(setdiff(packages, "base"), intersect(packages, "base"))
  for (pkg in packages) {
    original <- base_r_loader_original(lib, pkg)
    if (!file.exists(original)) {
      next
    }
    if (!file.copy(original, base_r_loader(lib, pkg), overwrite = TRUE)) {
      covr_abort(c(
        "Can't restore the loader of {.pkg {pkg}}.",
        i = "Its backup is {.path {original}}."
      ))
    }
    unlink(original, expand = FALSE)
  }
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
#' @seealso The article [Coverage of R itself](https://covr.r-lib.org/articles/base-r.html).
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
