# A copy of a compiled fixture package loaded with pkgload::load_all(), so the
# instrumented build doesn't write to the fixture.
local_compiled_package <- function(
  pkg = "TestCompiled",
  frame = parent.frame(),
  edit = NULL
) {
  dir <- withr::local_tempdir(.local_envir = frame)
  file.copy(test_path(pkg), dir, recursive = TRUE)
  path <- normalize_path(file.path(dir, pkg))
  if (!is.null(edit)) {
    edit(path)
  }
  # Other tests build the fixture in place, possibly at the same time
  clean_objects(path)
  clean_gcov(path)
  pkgload::load_all(path, quiet = TRUE)
  withr::defer(pkgload::unload(pkg), envir = frame)
  path
}

# TestCompiled with the kinds of bindings that `dll_bindings()` distinguishes
# besides its native routines: the DLL object of `useDynLib(dllinfo = )`, an
# active binding, a promise, and routine objects without a `dll` field.
local_compiled_package_with_bindings <- function(frame = parent.frame()) {
  edit <- function(path) {
    writeLines(
      c(
        "useDynLib(dllinfo = TestCompiled)",
        "useDynLib(TestCompiled, simple_)",
        "useDynLib(TestCompiled, simple3_)",
        "useDynLib(TestCompiled, simple4_)"
      ),
      file.path(path, "NAMESPACE")
    )
    writeLines(
      c(
        "makeActiveBinding('active_binding', function() stop('never'), environment())",
        "delayedAssign('lazy_promise', 1)",
        "routine <- function(name) {",
        "  structure(list(name = name), class = c('CallRoutine', 'NativeSymbolInfo'))",
        "}",
        "unrecorded_routine <- routine('simple_')",
        "unknown_routine <- routine('unknown_')"
      ),
      file.path(path, "R", "bindings.R")
    )
  }
  local_compiled_package(frame = frame, edit = edit)
}

# Makes the same calls as TestCompiled's tests, without nesting test_that()
local_compiled_test_script <- function(frame = parent.frame()) {
  file <- withr::local_tempfile(fileext = ".R", .local_envir = frame)
  writeLines(
    c(
      "simple(1); simple(2); simple(3); simple(-1)",
      "simple3(1); simple3(2)",
      "simple4(3L); simple4(-1L)"
    ),
    file
  )
  file
}

# TestRust loaded with pkgload::load_all(), with a Makevars that keeps cargo's
# `target` directory like savvy's, so later builds only recompile the crates
# that changed. `lib_rs` replaces its Rust code.
local_rust_package <- function(frame = parent.frame(), lib_rs = NULL) {
  edit <- function(path) {
    makevars <- file.path(path, "src", "Makevars")
    writeLines(
      sub("rm -Rf rust/target", "rm -f $(STATLIB)", readLines(makevars)),
      makevars
    )
    if (!is.null(lib_rs)) {
      writeLines(lib_rs, file.path(path, "src", "rust", "src", "lib.rs"))
    }
  }
  local_compiled_package("TestRust", frame = frame, edit = edit)
}

# Makes the same calls as TestRust's tests
local_rust_test_script <- function(frame = parent.frame()) {
  withr::local_tempfile(
    lines = "rust_sign(2); rust_sign(5); rust_sign(-3)",
    fileext = ".R",
    .local_envir = frame
  )
}

compiled_counts <- function(coverage, file) {
  tally <- tally_coverage(coverage)
  tally <- tally[basename(tally$filename) == file, ]
  stats::setNames(tally$value, tally$line)
}
