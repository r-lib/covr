#' Measure the coverage of installed packages, however their code is run
#'
#' @description
#' `instrument_packages()` instruments packages installed in a library, so
#' that every R process that loads one of them counts the code it runs and
#' saves the counts in a trace directory when it exits. `trace_coverage()`
#' reads the counts saved there into a single [coverage] object, and
#' `uninstrument_packages()` restores the packages. `local_instrumented_packages()`
#' instruments them until the calling function returns.
#'
#' This is the workflow [package_coverage()] uses, split up so that the code
#' can be run by anything: the tests of several packages, a test runner or
#' build system, or a script that starts many R processes. The traces of
#' several packages, and of processes that load more than one of them, are
#' kept apart, so one directory can collect the coverage of a set of packages,
#' e.g. those of a monorepo.
#'
#' @section Requirements:
#' * The packages must be installed with their source references, e.g. with
#'   `R CMD INSTALL --with-keep.source`. File names in the coverage are those
#'   of the source the packages were installed from.
#' * covr must be installed in a library that the R processes use, as the
#'   instrumented packages call it when they are loaded.
#' * Processes must exit normally to save their counts; processes that are
#'   killed lose them, and `trace_coverage()` warns (with class
#'   `covr_unsaved_trace`) about the processes that loaded an instrumented
#'   package but didn't save their counts.
#'
#' The R processes save their counts in the directory in the environment
#' variable `COVR_TRACE_DIR`, or if it is not set, in `trace_dir`. Compiled
#' code isn't instrumented.
#'
#' @section Example workflow:
#' ```r
#' lib <- "lib"
#' # Install the packages with their source references, e.g.
#' #   R CMD INSTALL --with-keep.source -l lib pkgA pkgB
#' instrument_packages(c("pkgA", "pkgB"), lib, trace_dir = "traces")
#'
#' # Then run anything that loads them from `lib`, e.g.
#' #   R_LIBS=lib Rscript -e 'testthat::test_dir("pkgA/tests/testthat")'
#'
#' cov <- trace_coverage("traces")
#' lcov(cov, "lcov.info")
#'
#' uninstrument_packages(c("pkgA", "pkgB"), lib)
#' ```
#'
#' @param packages The names of the packages to instrument, installed in
#'   `lib`.
#' @param lib The library the packages are installed in.
#' @param trace_dir The directory the counts are saved in, if the environment
#'   variable `COVR_TRACE_DIR` is not set when an R process loads an
#'   instrumented package. It is created if it doesn't exist.
#' @return `instrument_packages()`, `uninstrument_packages()` and
#'   `local_instrumented_packages()` return `packages`, invisibly.
#' @seealso [package_coverage()], which runs the tests of one or more packages
#'   and measures their coverage in one call.
#' @family instrumented packages
#' @export
instrument_packages <- function(
  packages,
  lib = .libPaths()[[1]],
  trace_dir = file.path(lib, "covr_traces")
) {
  check_packages(packages)
  if (!dir.exists(lib)) {
    covr_abort("Can't find the library {.path {lib}}.")
  }
  installed <- file.exists(file.path(lib, packages, "Meta", "package.rds"))
  if (!all(installed)) {
    covr_abort(
      "Can't find {.pkg {packages[!installed]}} in the library {.path {lib}}."
    )
  }
  lib <- normalize_path(lib)
  done <- file.exists(loader_original(lib, packages))
  if (any(done)) {
    covr_abort(c(
      "{.pkg {packages[done]}} {?is/are} already instrumented.",
      i = "Use {.fn uninstrument_packages} first."
    ))
  }
  dir.create(trace_dir, recursive = TRUE, showWarnings = FALSE)
  trace_dir <- normalize_path(trace_dir)

  # Restore the packages if one fails
  backed_up <- character()
  done <- FALSE
  on.exit(if (!done) uninstrument_packages(backed_up, lib), add = TRUE)
  for (pkg in packages) {
    if (!file.copy(loader(lib, pkg), loader_original(lib, pkg))) {
      covr_abort("Can't back up the loader script of {.pkg {pkg}}.")
    }
    backed_up <- c(backed_up, pkg)
  }
  pkgs <- lapply(packages, function(pkg) {
    desc <- read_description(file.path(lib, pkg, "DESCRIPTION"))
    desc$path <- file.path(lib, pkg)
    desc
  })
  instrument_library_packages(pkgs, lib, trace_dir)
  done <- TRUE
  invisible(packages)
}

#' @rdname instrument_packages
#' @export
uninstrument_packages <- function(packages, lib = .libPaths()[[1]]) {
  check_packages(packages, empty = TRUE)
  lib <- normalize_path(lib)
  for (pkg in packages) {
    original <- loader_original(lib, pkg)
    if (!file.exists(original)) {
      next
    }
    # The running R may still read the instrumented code of a namespace it has
    # loaded, through promises to read it when it is first used, so these are
    # read before it is removed.
    if (pkg %in% loadedNamespaces()) {
      ns <- asNamespace(pkg)
      if (
        identical(normalize_path(dirname(getNamespaceInfo(ns, "path"))), lib)
      ) {
        invisible(as.list(ns, all.names = TRUE))
      }
    }
    if (!file.copy(original, loader(lib, pkg), overwrite = TRUE)) {
      covr_abort(c(
        "Can't restore the loader script of {.pkg {pkg}}.",
        i = "Its backup is {.path {original}}."
      ))
    }
    unlink(
      c(
        paste0(instrumented_db_base(pkg, lib), c(".rdb", ".rdx")),
        instrumented_counters_file(pkg, lib),
        original
      ),
      expand = FALSE
    )
    remove_covr_hooks(pkg)
  }
  invisible(packages)
}

# The loader script of an instrumented package sets onLoad hooks (see
# `add_hooks()`) that stay in the session that loaded it, and would trace the
# package and restore the deleted counters if it were loaded again after it is
# restored, so they are removed. Other hooks are kept.
remove_covr_hooks <- function(pkg) {
  event <- packageEvent(pkg, "onLoad")
  hooks <- getHook(event)
  covr <- vlapply(hooks, function(hook) {
    any(grepl("covr", deparse(body(hook)), fixed = TRUE))
  })
  if (any(covr)) {
    setHook(event, hooks[!covr], "replace")
  }
}

#' @rdname instrument_packages
#' @param .local_envir The environment whose exit restores the packages.
#' @export
local_instrumented_packages <- function(
  packages,
  lib = .libPaths()[[1]],
  trace_dir = file.path(lib, "covr_traces"),
  .local_envir = parent.frame()
) {
  lib <- normalize_path(lib)
  instrument_packages(packages, lib, trace_dir)
  withr::defer(uninstrument_packages(packages, lib), envir = .local_envir)
  invisible(packages)
}

#' @rdname instrument_packages
#' @param paths The source directories of the packages, named by package, e.g.
#'   `c(pkgA = "src/pkgA")`. By default they are the directories the packages
#'   were installed from, as recorded in their source references. Give them
#'   if the packages were installed from somewhere else, e.g. a copy of the
#'   source in a sandbox, and the file names of their code are changed to be
#'   in these.
#' @param relative_path Whether file names are relative to the source
#'   directory of the package, or for several packages, of the directory that
#'   contains all of them, or absolute paths. If a string, file names are
#'   relative to that directory.
#' @inheritParams package_coverage
#' @return `trace_coverage()` returns a [coverage] object with the coverage of
#'   all the instrumented packages whose counts are in `trace_dir`. Files of
#'   the packages that the `.covrignore` file (see [exclusions]) in their source
#'   directory lists are left out.
#' @export
trace_coverage <- function(
  trace_dir = Sys.getenv(
    "COVR_TRACE_DIR",
    file.path(.libPaths()[[1]], "covr_traces")
  ),
  paths = NULL,
  relative_path = TRUE,
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  if (!dir.exists(trace_dir)) {
    covr_abort("Can't find the trace directory {.path {trace_dir}}.")
  }
  if (
    !is.null(paths) &&
      (!is.character(paths) ||
        is.null(names(paths)) ||
        any(!nzchar(names(paths))))
  ) {
    covr_abort("{.arg paths} must be a character vector named by package.")
  }
  dir <- trace_dir
  trace_dir <- normalize_path(trace_dir)
  traces <- merge_traces(trace_dir)
  warn_unsaved_traces(
    trace_dir,
    "loaded an instrumented package",
    "Did they exit normally?"
  )
  pkg_names <- traced_packages(traces)
  if (length(pkg_names) == 0) {
    covr_abort(
      "Can't find the coverage of any instrumented package in {.path {dir}}."
    )
  }
  unknown <- setdiff(names(paths), pkg_names)
  if (length(unknown) > 0) {
    covr_abort(
      "Can't find the coverage of {.pkg {unknown}} in {.path {dir}}."
    )
  }
  pkgs <- lapply(pkg_names, function(name) {
    path <- if (name %in% names(paths)) paths[[name]]
    list(package = name, path = path, ignore = TRUE)
  })
  pkgs <- trace_source_paths(traces, pkgs, move = !is.null(paths))
  coverage_of_packages(
    traces,
    pkgs,
    root = coverage_root(relative_path, pkgs),
    line_exclusions = line_exclusions,
    function_exclusions = function_exclusions
  )
}

check_packages <- function(packages, empty = FALSE) {
  if (
    !is.character(packages) ||
      (!empty && length(packages) == 0) ||
      anyNA(packages)
  ) {
    covr_abort("{.arg packages} must be a character vector of package names.")
  }
}

loader <- function(lib, pkg) {
  file.path(lib, pkg, "R", pkg)
}

# The loader script of the package as it was before it was instrumented.
loader_original <- function(lib, pkg) {
  paste0(loader(lib, pkg), ".covr-orig")
}

# Instrument the packages `pkgs` (from `as_package()`, or their DESCRIPTION
# with `path` set) installed in `lib`: ahead of time if they can be and
# `ahead_of_time` (see `instrument_package()`), and with the hooks that trace
# them when they are loaded and save their traces (see `add_hooks()`). The
# counts are saved in `trace_dir`, unless `COVR_TRACE_DIR` is set. The hooks are
# only added once all are instrumented, as instrumenting a package loads the
# packages it imports, which would save their traces.
instrument_library_packages <- function(
  pkgs,
  lib,
  trace_dir = lib,
  ahead_of_time = TRUE
) {
  ahead_of_time <- rep_len(ahead_of_time, length(pkgs))
  full_traversal <- lapply(pkgs, function(pkg) {
    getOption(
      "covr.full_traversal",
      # DESCRIPTION field names are lowercased by `read_description()`
      isTRUE(as.logical(pkg[[tolower("Config/covr/full_traversal")]]))
    )
  })
  counters_files <- Map(
    function(pkg, ahead_of_time, full_traversal) {
      if (ahead_of_time) {
        instrument_package(pkg, lib, full_traversal = full_traversal)
      }
    },
    pkgs,
    ahead_of_time,
    full_traversal
  )
  for (i in seq_along(pkgs)) {
    add_hooks(
      pkgs[[i]]$package,
      lib,
      fix_mcexit = should_enable_parallel_mcexit_fix(pkgs[[i]]),
      full_traversal = full_traversal[[i]],
      counters_file = counters_files[[i]],
      trace_dir = trace_dir
    )
  }
}

# The packages with traces in `traces`, whose keys start with the name of their
# package (see `scope_prefix()`).
traced_packages <- function(traces) {
  keys <- names(traces) %||% character()
  keys <- keys[grepl("/", keys, fixed = TRUE)]
  unique(sub("/.*$", "", keys))
}

package_traces <- function(traces, package) {
  keys <- names(traces) %||% character()
  traces[startsWith(keys, paste0(package, "/"))]
}

# Prefix the keys of the compiled traces `x` of the files of `pkg` with its
# name, like those of its R code, as files of different packages can have the
# same name (see `unscope_keys()`).
scope_compiled <- function(x, pkg) {
  if (!length(x)) {
    return(x)
  }
  files <- vcapply(x, function(trace) {
    get_source_filename(trace$srcref, full.names = TRUE)
  })
  inside <- path_in_roots(files, pkg$path)
  names(x)[inside] <- paste0(pkg$package, "/", names(x)[inside])
  x
}

# Set the `path` of the packages in `pkgs` that have none to the directory of
# the source they were installed from, as recorded in the source references of
# their traces. With `move`, the file names of the traces of the packages that
# have one are changed from that directory to their `path`.
trace_source_paths <- function(traces, pkgs, move = FALSE) {
  lapply(pkgs, function(pkg) {
    pkg_traces <- package_traces(traces, pkg$package)
    installed_from <- installed_source_path(pkg_traces)
    if (is.null(pkg$path)) {
      if (is.null(installed_from)) {
        covr_abort(c(
          "Can't find source references in the installed package {.pkg {pkg$package}}.",
          i = "Install it with {.code R CMD INSTALL --with-keep.source}."
        ))
      }
      pkg$path <- installed_from
    } else {
      pkg$path <- normalize_path(pkg$path)
      if (move && !is.null(installed_from)) {
        move_srcfiles(pkg_traces, installed_from, pkg$path)
      }
    }
    pkg
  })
}

# Change the file names of the srcrefs of `traces` in the directory `from` to
# be in `to`. The srcfiles are environments, shared by the traces of a file.
# The srcfiles of an installed package are aliases of one srcfile with the
# lines of all its files, which start with `#line` directives naming them, by
# which `traced_files()` finds the lines of each file, so these are moved too.
move_srcfiles <- function(traces, from, to) {
  from <- paste0(from, "/")
  to <- paste0(to, "/")
  move <- function(x) {
    inside <- startsWith(x, from)
    x[inside] <- paste0(to, substring(x[inside], nchar(from) + 1))
    x
  }
  moved <- new.env(parent = emptyenv())
  for (trace in traces) {
    srcfile <- attr(trace$srcref, "srcfile")
    # Many traces share a srcfile, which is only moved once, as `to` can be in
    # `from`.
    if (
      !is.environment(srcfile) ||
        !is.character(srcfile$filename) ||
        !is.null(moved[[address(srcfile)]])
    ) {
      next
    }
    moved[[address(srcfile)]] <- TRUE
    srcfile$filename <- move(srcfile$filename)
    original <- srcfile$original
    if (is.environment(original) && is.null(moved[[address(original)]])) {
      moved[[address(original)]] <- TRUE
      directives <- grepl("^#line [0-9]+ \"", original$lines)
      original$lines[directives] <- vcapply(
        original$lines[directives],
        function(line) {
          parts <- regmatches(
            line,
            regexec('^(#line [0-9]+ ")(.*)"$', line)
          )[[1]]
          if (length(parts)) {
            paste0(parts[[2]], move(parts[[3]]), "\"")
          } else {
            line
          }
        },
        USE.NAMES = FALSE
      )
    }
  }
  invisible()
}

# The directory file names are relative to, as `package_coverage()`'s
# `relative_path` gives it: the package's directory, or the directory that
# contains all the packages.
coverage_root <- function(relative_path, pkgs) {
  if (is.character(relative_path)) {
    if (length(relative_path) != 1L) {
      covr_abort(c(
        "{.arg relative_path} must be {.code TRUE}, {.code FALSE}, or a single string.",
        x = "It is a character vector of length {length(relative_path)}."
      ))
    }
    normalize_path(relative_path)
  } else if (isTRUE(relative_path)) {
    common_path(vcapply(pkgs, `[[`, "path"))
  } else {
    NULL
  }
}

# The deepest directory that contains all the (normalized) `paths`, or the
# path itself for one path.
common_path <- function(paths) {
  if (length(paths) == 1L) {
    return(paths)
  }
  parts <- strsplit(paths, "/", fixed = TRUE)
  n <- min(lengths(parts))
  common <- parts[[1]][seq_len(n)]
  for (p in parts[-1]) {
    same <- common == p[seq_len(n)]
    n <- if (all(same)) n else which(!same)[[1]] - 1L
    common <- common[seq_len(n)]
  }
  path <- paste(common, collapse = "/")
  # The root of a Unix file system
  if (!nzchar(path)) "/" else path
}

# The `package` attribute of the coverage of `pkgs`: the package of one, or the
# names and source directories of several.
coverage_package <- function(pkgs) {
  if (length(pkgs) == 1L) {
    pkg <- pkgs[[1]]
    pkg$ignore <- NULL
    return(pkg)
  }
  list(
    package = vcapply(pkgs, `[[`, "package"),
    path = vcapply(pkgs, `[[`, "path")
  )
}

# The coverage object of the `traces` of the packages `pkgs` (lists with their
# `package` name, source `path`, and whether to `ignore` the files in their
# `.covrignore`), and of their compiled code in `compiled`. Only the files of
# the packages are kept (see `filter_non_package_files()`), and the
# exclusions are applied.
coverage_of_packages <- function(
  traces,
  pkgs,
  root,
  compiled = NULL,
  line_exclusions = NULL,
  function_exclusions = NULL
) {
  coverage <- as_coverage(
    c(traces, compiled),
    package = coverage_package(pkgs),
    root = root
  )

  if (getOption("covr.filter_non_package", TRUE)) {
    coverage <- filter_non_package_files(coverage)
  }

  # Exclude generated files from Rcpp and cpp11 to avoid redundant coverage
  # information, and the files in `.covrignore`. Rcpp replaces dots in the
  # package name with underscores in the interfaces header. These paths are in
  # the package, so they are resolved against its root rather than the root
  # used for the output paths, which is `NULL` with `relative_path = FALSE`.
  package_exclusions <- unlist(lapply(pkgs, function(pkg) {
    c(
      file.path(
        pkg$path,
        c(
          "src/RcppExports.cpp",
          "R/RcppExports.R",
          file.path(
            "inst",
            "include",
            paste0(gsub(".", "_", pkg$package, fixed = TRUE), "_RcppExports.h")
          ),
          "src/cpp11.cpp",
          "R/cpp11.R"
        )
      ),
      if (isTRUE(pkg$ignore) && dir.exists(pkg$path)) {
        withr::with_dir(
          pkg$path,
          normalize_path(as.character(parse_covr_ignore()))
        )
      }
    )
  }))

  exclude(
    coverage,
    line_exclusions = c(package_exclusions, line_exclusions),
    function_exclusions = function_exclusions,
    path = root
  )
}

# Order the packages `pkgs` (from `as_package()`) so that each comes after the
# packages in `pkgs` that it depends on, imports or links to, as they must be
# installed first.
sort_by_dependencies <- function(pkgs) {
  pkg_names <- vcapply(pkgs, `[[`, "package")
  deps <- lapply(pkgs, function(pkg) {
    fields <- as.character(unlist(pkg[c("depends", "imports", "linkingto")]))
    deps <- trimws(sub("[ (].*$", "", trimws(unlist(strsplit(fields, ",")))))
    intersect(deps, pkg_names)
  })
  order <- integer()
  while (length(order) < length(pkgs)) {
    installed <- pkg_names[order]
    ready <- setdiff(
      which(vlapply(deps, function(d) all(d %in% installed))),
      order
    )
    # Packages can't depend on each other in a cycle, but keep the rest in
    # their order rather than loop forever
    if (length(ready) == 0) {
      ready <- setdiff(seq_along(pkgs), order)
    }
    order <- c(order, ready[[1]])
  }
  pkgs[order]
}
