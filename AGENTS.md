## This package

covr measures test coverage of R packages. `package_coverage()` installs an instrumented copy of the package into a temporary library and runs the tests, vignettes, examples or `code` in separate R processes; trace counts are saved to files by a finalizer and merged afterwards. Compiled code coverage uses gcov.

### Compatibility

- covr depends on `R (>= 4.0.0)`, so do not use the base pipe (`|>`), `\(x)` lambdas, or other syntax and functions newer than that.
- Functions from optional dependencies such as httr must be called with `pkg::fun()` (or a small wrapper in covr, which also makes them mockable), not imported with `@importFrom`. Importing them makes them load time dependencies, which causes cyclic namespace errors when computing coverage of those packages (#623).

### Tests

- The test packages in `tests/testthat/Test*/` and other fixtures under `tests/testthat/` are coverage inputs, and many tests assert exact line numbers in them. Do not reformat or edit them unless a test needs it; they are excluded from air in `air.toml`.
- `devtools::load_all()` loads every package listed in `DESCRIPTION`, so to check what loading covr itself does (e.g. which namespaces get loaded) install it with `R CMD INSTALL` into a temporary library and load it in a fresh R process.
- The R processes that `package_coverage()` starts load the *installed* covr, as the hooks added to the instrumented package call `covr:::` functions (`trace_environment()`, `register_trace()`, `save_trace()`, `fix_mcexit()`). `devtools::test()` only loads the source covr in the main process, so after changing these functions (or with an older covr installed) install this version first, e.g. `R CMD INSTALL -l "$lib" .` and run the tests with `R_LIBS="$lib"`.

### Measuring covr's own coverage

The instrumented package's startup hooks call `covr:::` functions, so the package being measured can't also be called covr. Instead, the installed covr is run on a copy of the source renamed to `covrShim`. `shim_package.sh` does the renaming (in DESCRIPTION, NAMESPACE, `R/`, `src/` and the tests) and `unshim_package.sh` reverses it. This is what `.github/workflows/test-coverage.yaml` does.

The scripts edit files in place, so run them on a throwaway copy rather than your working tree:

```sh
dir=$(mktemp -d) && git archive HEAD | tar -x -C "$dir" && cd "$dir"
lib=$(mktemp -d)
R CMD INSTALL -l "$lib" .  # install this version of covr first
sh shim_package.sh         # then rename the source to covrShim
R_LIBS="$lib" Rscript -e 'covr::report(covr::package_coverage())'
```

If you do shim your working tree, run `sh unshim_package.sh` before committing. `git archive HEAD` only includes committed changes, so commit (or copy the files) first if you want to measure uncommitted work.

When covr measures itself you will see `Can't find coverage from 1 R process that loaded covrShim`. This is expected: the SIGKILL test in `test-covr.R` ("package_coverage warns about processes that did not save a trace") starts a child R that loads the inner `TestSummary` hooks, which load the outer, instrumented `covrShim` (writing a `covr_pending_<pid>_*` marker to the outer install dir) before the child kills itself, so that child's `covrShim` coverage is lost by design.

### Running on Windows

Windows behaves differently in ways that matter to covr, e.g. `normalizePath()` turns a relative path that doesn't exist into an absolute one under the working directory, so check path handling there rather than relying on CI. From WSL, Windows R installed with rig can be run directly, e.g. `/mnt/c/Users/<user>/.local/bin/Rscript.exe` and `R.exe` (`rig list` shows the versions):

- Give it Windows paths (`C:/...`), and run it from a directory on the Windows filesystem; UNC paths to the WSL filesystem don't work as working directories.
- Copy the source to the Windows filesystem first, e.g. `git archive HEAD | tar -x -C /mnt/c/Users/<user>/AppData/Local/Temp/covr-win/src`.
- Its library may not have covr's dependencies; install them (and testthat and devtools) into a temporary library with `install.packages()`, then `R.exe CMD INSTALL -l <lib> <src>`. Building covr and source packages needs Rtools (`rig add rtools`).
- Environment variables set in WSL aren't passed to Windows programs unless listed in `WSLENV`, e.g. `R_LIBS=C:/... WSLENV=R_LIBS R.exe CMD INSTALL ...`; otherwise `R CMD INSTALL` can't find dependencies in the temporary library. In scripts, call `.libPaths()` instead.
- `Rscript -e` can segfault on multiline or complex code on Windows; write the code to a `.R` file instead.
- Don't set options such as `covr.record_tests` globally in a script that then runs the test suite; some tests rely on them being unset. Use `withr::with_options()`.

### Releases

The pkgdown site uses `development: mode: auto`. The site root (https://covr.r-lib.org/) is only rebuilt when the pkgdown workflow runs on a commit with a release version (e.g. `3.6.5`); development versions (e.g. `3.6.5.9000`) build to `/dev`.

- Push the release version commit on its own and let the pkgdown workflow finish before pushing the `.9000` version bump. If both are pushed together, only the latest commit is built and the released site is never updated.
- Publish a GitHub release for the version tag (`gh release create vX.Y.Z --verify-tag`). This also triggers a release build of the site.
- If the site root still shows the previous version, publish the missing GitHub release, or run the pkgdown workflow manually on the release tag.

## Package development

### Key commands

(All these functions have been optimized for agentic use, so they can be called directly without other arguments.)

```R
# Executing code
devtools::load_all()
code

# Tests
devtools::test() # all tests
devtools::test(filter = "^{name}") # tests for files starting with {name}
devtools::test_active_file("R/{name}.R") # tests for R/{name}.R
devtools::test_active_file("R/{name}.R", desc = 'blah') # single test with exact description "blah" (no regexp)

# Test coverage
devtools::test_coverage() # all files
devtools::test_coverage_active_file("R/{name}.R") # coverage for R/{name}.R from tests in tests/testthat/test-{name}.R

# Documentation
devtools::document() # redocument package
pkgdown::check_pkgdown() # check website

# Run complete R CMD check
devtools::check()
```

### Running R

There are three possible ways to run code, listed in rough order of desirability:

- If you're running inside Posit Assistant or otherwise have an
  `executeCode()` tool available, use it to run code in a session that the
  user can also interact with.

- Otherwise, if an R REPL (e.g. `mcp__r__repl` or `btw::run_r`) is
  available, use that. Note that `mcp__r__repl` uses a sandbox that blocks
  network requests and reads/writes outside of the current directory.

- Otherwise, use `Rscript -e "code"`. On Windows, `Rscript -e` can segfault on
  multiline or complex code; in that case, write it to a temporary `.R` file
  and run `Rscript path/to/file.R`.

### Code style

- Follow the tidyverse style guide.
- Always run `air format .` after generating code. (air is bundled with Positron so look there if you can't otherwise find it.)
- Use `function() {...}` for anonymous functions (see Compatibility above).

### Test style

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- All new code should have an accompanying test.
- If there are existing tests, place new tests next to similar existing tests.
- Strive to keep your tests minimal with few comments.
- Never put code in a `test-{name}.R` file outside of a `test_that()` block. Instead, use `tests/testthat/helper.R` or `tests/testthat/helper-{name}.R`.
- Avoid `expect_true()` and `expect_false()` in favor of a specific expectation with a better failure message. A few expectations in newer releases that you might not know about are `expect_all_true()`, `expect_all_equal()`, and `expect_r6_class()`.
- When testing errors and warnings:
  - Only use `expect_error()` or `expect_warning()` if the error or warning has a known class.
  - Generally, prefer `expect_snapshot(error = TRUE)` for errors and `expect_snapshot()` for warnings because these allow the user to review the full text of the output.
- Avoid the `.package` argument to `local_mocked_bindings()`; this modifies the namespace of another package, which is not good practice. Instead create a mockable version of the function in the current package. See `?local_mocked_bindings` for more details.

### Documentation

- Every user-facing function should be exported and have roxygen2 documentation.
- Internal functions should not have roxygen documentation.
- Wrap roxygen2 comments to 80 characters.
- Whenever you add a new (non-internal) documentation topic, also add the topic to `_pkgdown.yml`.
- Always re-document the package after changing a roxygen2 comment.
- Use `pkgdown::check_pkgdown()` to check that all topics are included in the reference index.

### `NEWS.md`

- Every user-facing change should be given a bullet in `NEWS.md`.
- Changes that shouldn't get a bullet:
    - Small documentation changes.
    - Internal refactorings.
    - Fixes to bugs introduced in the current dev version.
- Each bullet should briefly describe the change to the end user and mention the related issue in parentheses.
- Wrap bullets to 80 characters, matching the existing entries.
- If the change is related to a function, put the name of the function early in the bullet.
- If the change is related to an issue, include the issue number in parentheses.
- Only include a GitHub username if the PR was created by someone who isn't an author.
- Add new bullets at the top of the development version section.

## Git

- If the user asks you to commit, use markdown in the commit message, and don't line wrap.
- If the commit fixes an issue, include `Fixes #num.` on its own line.
- Only push when the user explicitly requests it.

## Writing

- Use sentence case for headings.
- Use US English.

### Proofreading

If the user asks you to proofread a file, act as an expert proofreader and editor with a deep understanding of clear, engaging, and well-structured writing.

Work paragraph by paragraph, always starting by making a TODO list that includes individual items for each top-level section.

Fix spelling, grammar, and other minor problems without asking the user. Label any unclear, confusing, or ambiguous sentences with a FIXME comment.

Only report what you have changed.
