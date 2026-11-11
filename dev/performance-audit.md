# covr performance audit

Audit of covr at `7e5599e` (3.6.5.9002, main on 2026-11-08), compared
with covr 3.5.1, 3.6.0, 3.6.4 and 3.6.5 from CRAN and with the commits
on main that changed performance since 3.6.5. Scripts are in
`performance-audit/` and their summarized output in
`performance-audit/results/`.

## Summary

- **On main, coverage costs 1.1–1.6x the uninstrumented install +
  tests.** For Luminescence (16,158 traces, 19.8 million evaluated
  expressions)
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
  takes 175 s against 107 s for `R CMD INSTALL` plus the tests. Nearly
  all of the extra time is in the test process: +64 s running the tests
  and +4 s instrumenting the package when it is loaded. For the small
  packages the fixed costs dominate and the overhead is 0.7–1 s.
- **[`report()`](https://covr.r-lib.org/dev/reference/report.md) is the
  slowest part of covr by far.** It takes 354 s for Luminescence, twice
  as long as computing the coverage, and 6 s for checkmate. 84% of that
  time goes to htmltools writing out a tag per line of source. A
  prototype that builds the same table as strings takes 0.31 s. It has
  been like this in every version measured (314–383 s).
- **`traced_files()` is quadratic in package size.** It splits the whole
  concatenated package source once for every file. On Luminescence that
  takes 1.7 s per call, and `exclude()`,
  [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md),
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
  `per_line()` and
  [`report()`](https://covr.r-lib.org/dev/reference/report.md) each call
  it at least once. Splitting once takes 0.09 s and gives identical
  results.
- **Every evaluated expression costs 1.1–1.3 µs in `covr:::count()`**,
  25–50x a cheap base R operation. That adds up to 22 s of
  Luminescence’s tests. A third of it is the
  `isTRUE(.current_test$record)` check, and a
  [`.Call()`](https://rdrr.io/r/base/CallExternal.html) counter costs
  27–30 ns.
- **Branch coverage (#279) would add about 6.5% to Luminescence’s test
  time at today’s cost per call.** `if` conditions run 8.6 million
  times, 43% of all counts, in all three packages (40–43%). With a C
  counter the cost would be about 0.3 s.
- **History.** The R \>= 4.4 regression (#567) is confirmed: on R 4.4.3,
  Luminescence takes 2,517 s with covr 3.6.4, 204 s with 3.6.5 (12x) and
  179 s with main (14x). Main is 12–14% faster than 3.6.5 on
  Luminescence, through \#643 (merging 6.8 s → 0.6 s) and \#644 (−18 s
  in the test process). For covr measuring its own coverage, \#668 took
  the run from 61 s to 220 s, more test changes took it to 397 s, and
  d277880 (#711) brought it back to 80 s. \#682 added 21%.

### Recommendations, ranked by gain for the effort and risk

| \# | Change | Measured or estimated gain | Effort / risk |
|----|----|----|----|
| 1 | Build [`report()`](https://covr.r-lib.org/dev/reference/report.md)’s source table as strings, not a tag per line | Luminescence 354 s → ≈8 s (table 288 s → 0.31 s); checkmate 6 s → \<1 s | Small / low |
| 2 | Split the concatenated source once in `traced_files()` | 1.72 s → 0.09 s per call; −1.6 s in [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) and in each of [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md), [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md), [`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md), [`print()`](https://rdrr.io/r/base/print.html); −4.8 s in [`report()`](https://covr.r-lib.org/dev/reference/report.md) | Small / low |
| 3 | Decide whether to record tests when instrumenting, not in every [`count()`](https://covr.r-lib.org/dev/reference/count.md) | [`count()`](https://covr.r-lib.org/dev/reference/count.md) 1.1–1.3 µs → 0.65–0.77 µs; ≈ −9 s of Luminescence’s tests | Small / low |
| 4 | Index the parse data once in `parse_children()` | up to −2 s of the 4.1 s instrumentation in each process that loads Luminescence | Small–medium / low |
| 5 | Count in C: `.Call(<symbol>, <index>)` | 27–30 ns per count instead of ≈1.1 µs: ≈ −22 s (−15%) of Luminescence’s tests; branch coverage almost free | Medium–high / medium |
| 6 | Document sharding the tests across CI jobs, combining with [`c()`](https://rdrr.io/r/base/c.html) | With 4 shards Luminescence takes ≈64 s per job instead of 175 s (estimate) | Docs only / none |
| 7 | Build [`to_cobertura()`](https://covr.r-lib.org/dev/reference/covr-deprecated.md)’s XML as strings | Part of its 9.3 s on Luminescence (53% is in `xml_add_child()`) | Small / low |

Measured and not worth changing: trace file serialization (0.5 s to
save, 0.1 s to merge), the installation (no slower than a normal
install), and turning off the byte-code JIT (3% faster, within noise).

## Setup

- Machine: WSL2 (Linux 6.18) on an Intel i7-12700KF, 20 logical CPUs, 16
  GB shared with other work. All timings are wall clock. Up to four
  benchmark processes ran at once, so expect about ±5% noise between
  runs. Medians of 2 runs; the individual runs are in
  `results/summary.md`.

- R 4.3.3 (`/usr/bin/R`, Ubuntu build), 4.4.3 and 4.6.2 (rig). Each R
  version has its own library of dependencies (P3M binaries; the same
  versions of testthat 3.3.2 and htmltools 0.5.9) and a separate library
  for each covr version, installed from the CRAN archive. Main is
  installed from `git archive HEAD`.

- Benchmark packages, built from CRAN source tarballs:

  | Package | Code | Traces | Evaluated expressions in the tests | Tests |
  |----|----|----|----|----|
  | forcats 1.0.1 | R | 736 | 9,697 | 149 |
  | checkmate 2.3.4 | R + C | 879 | 33,718 | 169 |
  | Luminescence 0.9.25 | R + C++ (Rcpp) | 16,158 | 19,849,339 | 247 |

- Every covr version runs the tests the same way:
  `package_coverage(type = "none", code = "Sys.setenv(NOT_CRAN = 'true'); testthat::test_dir(<installed tests>, load_package = 'installed', stop_on_failure = FALSE, ...)")`.
  `NOT_CRAN` matters. Without it, 237 of Luminescence’s 247 tests skip
  and coverage is 15% instead of 90%. Luminescence has 1 failure and 4
  errors with current dependencies, and rjags (a Suggests) can’t be
  installed, so its tests skip.

- Skipped:

  - covr 3.5.1, 3.6.0 and 3.6.4 can’t be loaded on R 4.6
    (`undefined symbol: SET_BODY`; fixed in 3.6.5 by \#587).
  - Luminescence with covr 3.5.1 and 3.6.0 on R 4.4.3, which would take
    about 40 minutes per run. `R/parse_data.R`, the cause of \#567, is
    identical in 3.5.1, 3.6.0 and 3.6.4 (same md5), so 3.6.4 stands in
    for them. forcats and checkmate were run with all versions.
  - [`report()`](https://covr.r-lib.org/dev/reference/report.md) is only
    timed in the first run of each combination. It takes 5–6 minutes for
    Luminescence.

## 1. Where performance stands on main

### End to end (R 4.6.2)

| Package | Without coverage: install + tests | [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) | Ratio | [`report()`](https://covr.r-lib.org/dev/reference/report.md) afterwards |
|----|----|----|----|----|
| forcats | 1.4 + 2.6 = 4.0 s | 5.0 s | 1.25x | 1.2 s |
| checkmate | 2.4 + 6.9 = 9.3 s | 10.0 s | 1.08x | 6.2 s |
| Luminescence | 21.3 + 85.9 = 107.2 s | 175.0 s | 1.63x | 353.8 s |

### Phases

Each phase of
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
was run separately (`bench-phases.R`), with a normal install and test
run of the same package as the baseline. The test process loads the
installed covr main (`covr_in_child` in `results/summary.md`).

| Phase (seconds) | forcats | checkmate | Luminescence |
|----|----|----|----|
| Baseline `R CMD INSTALL` | 1.4 | 2.4 | 21.3 |
| covr install (`-O0 --coverage`, keep.source, keep.parse.data) | 1.3 | 2.2 | 19.4 |
| Baseline load namespace | 0.03 | 0.01 | 0.15 |
| Load + `trace_environment()` | 0.15 | 0.4 | 4.1 |
| Baseline tests | 2.6 | 6.9 | 85.9 |
| Tests, instrumented | 3.0 | 7.2 | 150.3 |
| `save_trace()` | 0.01 | 0.03 | 0.5 |
| `merge_coverage()` | 0.00 | 0.01 | 0.1 |
| `run_gcov()` | — | 0.1 | 0.2 |
| [`as_coverage()`](https://covr.r-lib.org/dev/reference/as_coverage.md) + `exclude()` | 0.06 | 0.2 | 2.7 |
| [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) end to end | 5.0 | 10.0 | 175.0 |
| [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md) | 0.04 | 0.2 | 2.6 |
| [`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md) | 0.03 | 0.2 | 2.6 |
| [`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md) | 0.03 | 0.2 | 2.6 |
| [`print()`](https://rdrr.io/r/base/print.html) | 0.2 | 0.5 | 3.4 |
| [`coverage_to_list()`](https://covr.r-lib.org/dev/reference/coverage_to_list.md) | 0.04 | 0.2 | 2.4 |
| [`to_cobertura()`](https://covr.r-lib.org/dev/reference/covr-deprecated.md) | 0.2 | 0.6 | 9.3 |
| [`report()`](https://covr.r-lib.org/dev/reference/report.md) | 1.2 | 6.2 | 353.8 |

- **Install.** The instrumented install is not slower than a normal one:
  `-O0` offsets `--coverage` and keeping the sources.
- **gcov** takes ≤0.2 s for these packages, which have few compilation
  units. \#611 (3.6.5) and \#712 (main) targeted packages with many.
- **The test process** takes 69 s longer (load +4 s, tests +64 s, saving
  the trace +0.5 s). The install is 2 s faster and the main process
  steps add 3 s. The next section breaks down the test process.

### Where the test process spends the extra time (Luminescence)

From the Rprof profile (10 ms sampling) of the instrumented test process
(`results/profile-Luminescence-test-process.txt`), 138 s sampled:

| Cost | Seconds | Share | Evidence |
|----|----|----|----|
| `covr:::count()` | 22.4 | 16% | 1.13 µs × 19.85 M counts. Includes 5.3 s in [`isTRUE()`](https://rdrr.io/r/base/Logic.html) |
| JIT compilation of instrumented functions (`cmpfun`) | 17.7 | 13% | Instrumented functions lose their install-time bytecode. Includes 3.9 s adding constants to the constant pool (`putconst`) |
| Instrumentation at load | 4.2 | 3% | [`trace_calls()`](https://covr.r-lib.org/dev/reference/trace_calls.md) 3.3 s, of which `impute_srcref()` → `parse_children()` 2.0 s; `get_parse_data()` 0.19 s; `replacements_S4()` 0.24 s |
| Rest of the +64 s | ≈24 |  | Slower execution of the larger instrumented bodies (`if (TRUE) { covr:::count(key); expr }` around every expression), not attributable from the profile |

With the JIT off (`R_ENABLE_JIT=0`, `results/jit-and-branch-counts.txt`)
the instrumented tests take 143.0 s against 147.6 s with it on, and the
uninstrumented tests take 82.8 s either way. The time spent compiling
roughly equals what the compiled code saves, so turning off the JIT
gains nothing.

### Memory

| Process | forcats | checkmate | Luminescence |
|----|----|----|----|
| Test process, baseline (peak RSS) | 123 MB | 128 MB | 755 MB |
| Test process, instrumented, after `save_trace()` | 128 MB | 146 MB | 854–875 MB |
| Main process after [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) | 89 MB | 116 MB | 186 MB (3.6.5: 265 MB) |
| Main process after [`report()`](https://covr.r-lib.org/dev/reference/report.md) | 139 MB | 263 MB | 1,008–1,317 MB |
| Trace files | 0.05 MB | 0.07 MB | 5.35 MB in 4 files (largest 1.36 MB) |

Instrumentation adds 4–16% to the test process.
[`report()`](https://covr.r-lib.org/dev/reference/report.md) is again
the outlier. It raises the main process from 186 MB to over 1 GB, and it
is the peak memory of the whole run.

## 2. Changes across versions

### Released versions (median seconds of `package_coverage()`)

| Package      | covr  | R 4.3.3 | R 4.4.3                        | R 4.6.2    |
|--------------|-------|---------|--------------------------------|------------|
| forcats      | 3.5.1 | 4.8     | 5.1                            | can’t load |
|              | 3.6.0 | 5.0     | 5.3                            | can’t load |
|              | 3.6.4 | 5.0     | 5.3                            | can’t load |
|              | 3.6.5 | 4.9     | 4.6                            | 4.9        |
|              | main  | 4.9     | 4.6                            | 5.0        |
| checkmate    | 3.5.1 | 14.6    | 13.5                           | can’t load |
|              | 3.6.0 | 14.3    | 13.4                           | can’t load |
|              | 3.6.4 | 14.4    | 12.9                           | can’t load |
|              | 3.6.5 | 13.7    | 9.7                            | 10.8       |
|              | main  | 13.5    | 10.1                           | 10.6       |
| Luminescence | 3.5.1 | 179.6   | skipped                        | can’t load |
|              | 3.6.0 | 189.4   | skipped                        | can’t load |
|              | 3.6.4 | 197.1   | **2,517.0** (2,465.7, 2,568.3) | can’t load |
|              | 3.6.5 | 187.4   | 203.6                          | 217.1      |
|              | main  | 171.4   | 178.9                          | 186.4      |

Luminescence, other steps (median seconds;
[`report()`](https://covr.r-lib.org/dev/reference/report.md) from a
single run):

| covr | R | `merge_coverage()` | `exclude()` | [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md) | [`report()`](https://covr.r-lib.org/dev/reference/report.md) | Peak RSS, any process |
|----|----|----|----|----|----|----|
| 3.5.1 | 4.3.3 | 2.1 | 2.7 | 2.6 | 317.0 | 1,010 MB |
| 3.6.0 | 4.3.3 | 2.6 | 2.7 | 2.6 | 314.1 | 1,075 MB |
| 3.6.4 | 4.3.3 | 2.9 | 3.1 | 3.2 | 367.3 | 1,074 MB |
| 3.6.4 | 4.4.3 | 8.1 | 2.5 | 2.6 | 346.8 | 1,022 MB |
| 3.6.5 | 4.4.3 | 7.2 | 2.6 | 2.8 | 371.9 | 1,030 MB |
| 3.6.5 | 4.6.2 | 7.3 | 2.7 | 2.6 | 336.8 | 1,027 MB |
| main | 4.6.2 | 0.4 | 2.8 | 2.8 | 362.8 | 939 MB |

- **\#567 / \#588 (fixed in 3.6.5).** On R 4.4.3, covr ≤3.6.4 is 12x
  slower on Luminescence (2,517 s against 204 s with 3.6.5). This is
  close to the 2,395 s against 170 s reported in \#567. The time is all
  in the test process (`run_code` 2,487 s), where every nested
  conditional recomputed the parse data of the whole package. Smaller
  packages show it too: checkmate takes 12.9–13.5 s with ≤3.6.4 against
  9.7 s with 3.6.5 (+33%), and forcats 5.1–5.3 s against 4.6 s. R 4.3.3
  is unaffected (197 s with 3.6.4). On R 4.3.3 checkmate is slower with
  every covr version, because the uninstrumented tests are slower on the
  Ubuntu build of R.
- **3.5.1 → 3.6.4** changed nothing measurable apart from that
  regression.
- **3.6.5 → main**: Luminescence takes 12–14% less time (217 → 186 s on
  R 4.6.2, 204 → 179 s on R 4.4.3, 187 → 171 s on R 4.3.3), and the main
  process uses 186 MB instead of 265 MB after
  [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md).
- **[`report()`](https://covr.r-lib.org/dev/reference/report.md) has
  taken 5–6 minutes in every version.** Dropping DT in \#725 didn’t
  change that, because the per-line tags were already there.

### Commits on main since 3.6.5

Luminescence on R 4.6.2 at each commit and its parent
(`results/summary.md`, “Development history”):

| Commit | Change | Total | Tests (`run_code`) | `merge_coverage()` | gcov | [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md) |
|----|----|----|----|----|----|----|
| e734fdf | parent of \#643 (≈3.6.5) | 207.9 | 177.5 | 6.8 | 0.3 | 2.4 |
| 853f3df | \#643 faster `merge_coverage()` | 194.3 | 171.4 | **0.6** | 0.3 | 2.5 |
| 9183955 | \#644 parse text only for terminal tokens | **176.5** | **153.7** | 0.6 | 0.4 | 2.5 |
| f1208d1 → c0df663 | \#668 warn about unsaved traces | 175.4 → 172.2 | 152.5 → 149.8 | 0.6 | 0.3 | 2.5 |
| 7d9b5ea → 39b6848 | \#682 braceless branches | 167.7 → 174.7 | 145.8 → 152.1 | 0.6 → 0.7 | 0.3 → 0.4 | 2.4 → 2.5 |
| 0159c7e → 7d763f3 | \#691 minimum line rule | 178.6 → 179.9 | 155.6 → 156.9 | 0.6 → 0.7 | 0.4 → 0.3 | **2.5 → 2.9** |
| 1b44f08 → d277880 | \#711 register trace in onLoad hook | 175.6 → 176.3 | 153.0 → 153.8 | 0.6 | 0.3 | 2.9 → 2.8 |
| d277880 → 9328a71 | \#707 smaller trace files | 176.3 → 174.0 | 153.8 → 151.9 | **0.6 → 0.4** | 0.3 | 2.8 |
| 9ba4bc2 → 02798cb | \#712 gcov JSON | 176.4 → 174.6 | 154.6 → 153.2 | 0.4 | **0.3 → 0.1** | 2.8 → 2.9 |

- **\#643**: merging Luminescence’s trace files went from 6.8 s to 0.6 s
  (0.1 s in the phase benchmark on main).
- **\#644**: parse text for terminal tokens only. The tests took 153.7 s
  in Luminescence’s test process against 171.4 s at its parent (−18 s).
  On the parse data alone, `getParseData(includeText = TRUE)` takes 4.36
  s for Luminescence’s 143 files and `includeText = NA` takes 0.11 s
  (`results/microbench-parse-Luminescence.txt`). Load + instrumentation
  is now 4.1 s.
- **\#682** added 4% to Luminescence (within noise) and 21% to covr’s
  own coverage run, which tests many small fixture packages (see below).
- **\#691** added 0.4 s (+16%) to
  [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
  on Luminescence.
- **\#707** made the trace files smaller: Luminescence 6.33 → 5.35 MB
  (−15%), checkmate 0.12 → 0.07 MB (−42%), forcats unchanged at 0.05 MB
  (`results/trace-size.txt`). Merging went from 0.6 to 0.4 s.
- **\#712** cut gcov from 0.3 to 0.1 s. Luminescence has only a few
  compilation units, so packages with many will see a larger gain.
- **\#668 and \#711** didn’t change Luminescence. They only affect a
  package that is loaded while covr is lazy-loaded, which is the case
  when covr measures its own coverage.

covr measuring its own coverage (`bench-self.sh`, as in the
test-coverage workflow; R 4.6.2; each commit runs its own test suite, so
compare a commit with its parent):

| Commit | Change | Median (runs) |
|----|----|----|
| fb63ffb | v3.6.5 | 49.5 s (50.4, 48.5) |
| f1208d1 | parent of \#668 | 61.0 s (61.6, 60.4) |
| c0df663 | \#668 calls `covr:::register_trace()` from the load script | **220.1 s** (220.9, 219.3), 3.6x |
| 7d9b5ea | parent of \#682 | 235.0 s (238.9, 231.0) |
| 39b6848 | \#682 | **283.9 s** (284.3, 283.4), +21% |
| 1b44f08 | parent of d277880 | 396.8 s (394.9, 398.7) |
| d277880 | \#711 registers the trace in an onLoad hook | **79.6 s** (79.7, 79.5), 5.0x faster |
| 7e5599e | main | 100.0 s (101.2, 98.8) |

The ~4x slowdown from \#668 and the ~20% from \#682 are confirmed, and
so is the fix in d277880. Main is 25% slower than d277880; the test
suite grew from 256 to 298 `test_that()` blocks since, e.g. for the gcov
JSON parser and compiled code in the session \[INFERENCE: the cause of
the difference was not profiled\].

## 3. Recommendations

### 1. `report()`: build the source table as strings

[`report()`](https://covr.r-lib.org/dev/reference/report.md) creates a
`<tr>` with three `<td>`s and a `<pre>` for every line of every file:
66,339 rows for Luminescence. In the profile
(`results/profile-Luminescence-report.txt`, 344 s sampled), 328 s are in
[`htmltools::save_html()`](https://rstudio.github.io/htmltools/reference/save_html.html)
→ `renderTags()`, and 288 s (84%) in `collapseBuffer()` →
[`paste()`](https://rdrr.io/r/base/paste.html) inside htmltools’
`textWriter`. Building the tags
([`report_html()`](https://covr.r-lib.org/dev/reference/report_html.md))
takes only about 16 s; writing them out is the problem \[INFERENCE: the
profile doesn’t show why `collapseBuffer()` is so expensive at this
size; it looks like the text buffer is collapsed again and again as the
tags are written\].

`microbench-post.R` has a prototype, `source_table_html()`, that builds
the same rows with vectorized
[`paste0()`](https://rdrr.io/r/base/paste.html) and
[`htmltools::htmlEscape()`](https://rstudio.github.io/htmltools/reference/htmlEscape.html)
and wraps the result in `HTML()`:

| Step (Luminescence) | Time |
|----|----|
| `renderSourceTable()` + `renderTags()` (current) | 287.7 s |
| Prototype + `renderTags()` | 0.31 s |
| `to_report_data()` (`per_line()` + [`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)) | 7.1 s |

This would take
[`report()`](https://covr.r-lib.org/dev/reference/report.md) from 354 s
to about 8 s, and to about 3 s together with recommendation 2. It also
removes most of the 1 GB peak.
[`file_report_html()`](https://covr.r-lib.org/dev/reference/file_report.md)
uses the same `renderSourceTable()`. The risk is in escaping, which
`htmlEscape()` handles the same way as the tags. The existing report
tests would catch changes in the markup.

### 2. `traced_files()`: split the package source once

Each traced file of an installed package has a `srcfilealias` whose
lines are the whole concatenated package source, with `#line`
directives. `traced_files()` calls
[`getSrcLines()`](https://rdrr.io/r/base/srcfile.html) and a `rex` regex
with two captures on all of those lines **for each file**. That is
O(files × package lines): 144 traced files × 67,555 lines for
Luminescence. `traced_files()` is called by `exclude()` (inside
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)),
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
(through `non_code_lines()`), `per_line()`,
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
[`zero_coverage()`](https://covr.r-lib.org/dev/reference/zero_coverage.md),
[`print()`](https://rdrr.io/r/base/print.html),
[`to_cobertura()`](https://covr.r-lib.org/dev/reference/covr-deprecated.md),
[`coverage_to_list()`](https://covr.r-lib.org/dev/reference/coverage_to_list.md)
and [`report()`](https://covr.r-lib.org/dev/reference/report.md). In the
profiles of
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md)
and
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md),
it accounts for 72–74% of their time.

The `split_once()` prototype in `microbench-post.R` splits the source
with the existing `split_on_line_directives()` once per original
srcfile, keyed by its address, and
[`stopifnot()`](https://rdrr.io/r/base/stopifnot.html) checks that the
result is identical:

| Luminescence               | Time    |
|----------------------------|---------|
| `traced_files()` (current) | 1.723 s |
| Split once                 | 0.094 s |

With this change
[`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md)
would take 1.6 s less, and each post-processing call would take 1.6 s
less per `traced_files()` call it makes: about 2.6 s → 1 s for
[`percent_coverage()`](https://covr.r-lib.org/dev/reference/percent_coverage.md),
and 4.8 s less in
[`report()`](https://covr.r-lib.org/dev/reference/report.md). The
regexes in `non_code_lines()` are not the problem: replacing
[`rex::re_matches()`](https://rex.r-lib.org/reference/re_matches.html)
with [`grepl()`](https://rdrr.io/r/base/grep.html) saves only 0.011 s
(0.036 → 0.025 s).

### 3. `count()`: decide whether to record tests when instrumenting

``` r

count <- function(key) {
  .counters[[key]]$value <- .counters[[key]]$value + 1L
  if (isTRUE(.current_test$record)) count_test(key)
}
```

From `microbench.R` (byte-compiled loops of 10^6 iterations, median of
5, minus an empty loop):

| Per call | R 4.3.3 | R 4.4.3 | R 4.6.2 |
|----|----|----|----|
| `x + 1` | 22 ns | 42 ns | 46 ns |
| `covr:::count(key)` | 1,115 ns | 1,238 ns | 1,315 ns |
| `isTRUE(.current_test$record)` alone | 329 ns | 313 ns | 333 ns |
| [`count()`](https://covr.r-lib.org/dev/reference/count.md) without the [`isTRUE()`](https://rdrr.io/r/base/Logic.html) check | 648 ns | 705 ns | 769 ns |
| `.Call(<native symbol>, <index constant>)` C counter | 30 ns | 27 ns | 29 ns |
| Instrumented 3-statement function, overhead per count | 1,114 ns | 1,106 ns | 1,471 ns |

- The `:::` lookup costs 58 ns and is not the problem.
- The nested replacement `.counters[[key]]$value <- ...` costs 444 ns.
- [`isTRUE()`](https://rdrr.io/r/base/Logic.html) is a closure call on
  every count, and the profile confirms it: 5.3 of
  [`count()`](https://covr.r-lib.org/dev/reference/count.md)’s 22.4 s in
  the Luminescence test process.

`covr.record_tests` is set by the load hooks before
`trace_environment()` runs, so
[`trace_calls()`](https://covr.r-lib.org/dev/reference/trace_calls.md)
could emit `covr:::count_and_record(key)` when tests are recorded and a
[`count()`](https://covr.r-lib.org/dev/reference/count.md) without the
check otherwise. That makes
[`count()`](https://covr.r-lib.org/dev/reference/count.md) 40% cheaper,
about −9 s of Luminescence’s tests, for a small and local change.

### 4. Instrumentation at load: index the parse data

Every process that loads the instrumented package pays for its
instrumentation again. For Luminescence that is 4.1 s against 0.15 s for
a normal load, and its run loaded the package in 4 processes (4 trace
files). Tests, examples and vignettes also run in separate processes, as
do tests that start callr or forked workers. In the profile, 2.0 of the
4.2 s are in `impute_srcref()` → `parse_children()`. For each
conditional, that compares `line1`, `line2`, `col1`, `col2` and `token`
against every row of the file’s parse data, and then subsets it with
`pd$parent == expr_id`. The parse data itself is cheap since \#644:
`get_parse_data()` takes 0.19 s, and `diagnose-parse-fallback.R` found
no fallback to the slow whole-package
[`getParseData()`](https://rdrr.io/r/utils/getParseData.html) path on R
4.6.

Keying the per-file parse data once by `paste(line1, col1, line2, col2)`
for `expr` tokens, and splitting the children by `parent`, would make
each lookup O(1) and save up to 2 s per process for Luminescence
(estimate from the profile). A bigger step would be instrumenting once,
at install time, and loading the instrumented functions in each process.
That is a large change to how covr hooks into packages, and it is not
proposed here.

### 5. Count in C

A [`.Call()`](https://rdrr.io/r/base/CallExternal.html) to a native
routine, with the routine’s address and the counter’s integer index as
constants in the call, costs 27–30 ns, 40x less than
[`count()`](https://covr.r-lib.org/dev/reference/count.md). The
prototype in `microbench.R` checks that the C counter reaches the
expected count. For Luminescence this would save about 21 of the 22.4 s
in [`count()`](https://covr.r-lib.org/dev/reference/count.md), and the
smaller constants could also reduce the 3.9 s of `putconst` during JIT
compilation \[INFERENCE: not measured\].

The cost is a redesign of the counters:

- counts kept in a growable C array, indexed from the trace key;
- `save_trace()` and `merge_coverage()` reading the counts from it;
- recording tests
  ([`count_test()`](https://covr.r-lib.org/dev/reference/count_test.md))
  kept on a separate R path;
- forked processes are fine, since they copy the array.

Do it after recommendation 3, and before or together with branch
coverage, which multiplies the number of calls (next section).

### Expected cost of branch coverage (#279)

The planned opt-in branch coverage adds one call for each evaluated
`if`. `phase-child.R` counts how often each `if` condition ran in the
tests, using the counter of the condition in the instrumented function
bodies (`results/jit-and-branch-counts.txt`):

| Package      | `if` statements | `if` evaluations | All counts | Extra calls |
|--------------|-----------------|------------------|------------|-------------|
| forcats      | 154             | 4,094            | 9,697      | +42%        |
| checkmate    | 208             | 13,468           | 33,718     | +40%        |
| Luminescence | 3,510           | 8,620,002        | 19,849,462 | +43%        |

The expected cost for Luminescence’s 150 s of instrumented tests:

| Cost per branch call | Extra time | Increase |
|----|----|----|
| Today’s [`count()`](https://covr.r-lib.org/dev/reference/count.md), 1.13 µs | +9.7 s | +6.5% |
| Today’s overall overhead per count (64 s / 19.85 M = 3.2 µs) | +28 s | +19% |
| [`count()`](https://covr.r-lib.org/dev/reference/count.md) without the [`isTRUE()`](https://rdrr.io/r/base/Logic.html) check (rec. 3), 0.7 µs | +6 s | +4% |
| C counter (rec. 5), 30 ns | +0.3 s | +0.2% |

Each branch call should not repeat the `isTRUE(.current_test$record)`
check (rec. 3). The forcats and checkmate overhead stays under 0.1 s in
every case.

### 6. Sharding tests in CI

For Luminescence, the costs paid once per job are about 19 s to install,
4 s to instrument each process and about 3 s to post-process. The 150 s
of tests divide among the shards. With 4 shards a job would take ≈ 19 +
4 + 150/4 + 3 ≈ 64 s instead of 175 s \[INFERENCE: estimated from the
phases, not run\]. covr can already combine the results of the shards
with [`c()`](https://rdrr.io/r/base/c.html)
([`c.coverage()`](https://covr.r-lib.org/dev/reference/c.coverage.md) on
main). Each shard can run
`package_coverage(type = "none", code = testthat::test_dir(..., filter = <shard>))`
and save the result. A vignette section or an example workflow would
cover it without changes to covr. Running the tests in parallel workers
within one job (testthat’s `Config/testthat/parallel`) should also work,
since each worker saves its own trace, but each pays the 4 s load cost
\[INFERENCE: not tested\].

### 7. `to_cobertura()`

It takes 9.3 s for Luminescence.
[`xml2::xml_add_child()`](http://xml2.r-lib.org/reference/xml_replace.md)
accounts for 4.6 s, 3.2 s of it setting attributes, because nodes are
added one at a time;
[`tally_coverage()`](https://covr.r-lib.org/dev/reference/tally_coverage.md)
takes 2.3 s (`results/profile-Luminescence-to_cobertura.txt`). Writing
the XML as strings, as in recommendation 1, would remove most of the
xml2 time. This is low priority: it is 5% of a Luminescence run, and
much less in smaller packages.

### Not worth changing

- **Trace files**: `save_trace()` takes 0.5 s and `merge_coverage()` 0.1
  s for Luminescence. In `microbench.R`, `portable_srcfiles()` takes
  0.21 s and [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) with
  gzip 0.30 s (1.6 MB). Without compression it takes 0.07 s but the file
  is 9.8 MB. The counts alone would serialize to 1.1 MB; the rest is
  srcrefs and source lines.
- **Byte-code JIT**: see above. Turning it off saves 3%, within noise.
- **Install**: covr’s install takes as long as a normal install (19.4 s
  against 21.3 s for Luminescence).

## Commands

The scripts take the benchmark directory (`/tmp/covr-bench` here) as an
argument and leave everything in it. Before heavy runs, `mem-ok 4000`
was checked, and each run was capped with `memcap 6G`.

``` sh
# Libraries: dependencies (P3M binaries) and one library per covr version
# (3.5.1, 3.6.0, 3.6.4, 3.6.5 from the CRAN archive, main from HEAD) for each R
sh performance-audit/setup.sh /tmp/covr-bench
# covr at the commits of the development history (R 4.6.2)
sh performance-audit/setup-commits.sh /tmp/covr-bench 4.6.2 \
  v3.6.5 853f3df^ 853f3df 9183955 c0df663^ c0df663 39b6848^ 39b6848 \
  7d763f3^ 7d763f3 d277880^ d277880 9328a71 02798cb^ 02798cb HEAD

B=/tmp/covr-bench
PKGS="$B/src/forcats_1.0.1.tar.gz $B/src/checkmate_2.3.4.tar.gz $B/src/Luminescence_0.9.25.tar.gz"

# Released versions x packages x R versions, 2 runs each
VERSIONS="3.5.1 3.6.0 3.6.4 3.6.5 main" TIMEOUT=5000 \
  sh performance-audit/run-versions.sh $B 4.3.3 2 $PKGS
VERSIONS="3.5.1 3.6.0 3.6.4 3.6.5 main" TIMEOUT=5000 \
  SKIP="4.4.3-3.5.1-Luminescence 4.4.3-3.6.0-Luminescence" \
  sh performance-audit/run-versions.sh $B 4.4.3 2 $PKGS
VERSIONS="3.6.5 main" TIMEOUT=5000 sh performance-audit/run-versions.sh $B 4.6.2 2 $PKGS

# Development history: Luminescence at each commit and its parent
OUT_SUBDIR=history REPORT=false TIMEOUT=3000 \
  VERSIONS="e734fdf 853f3df 9183955 f1208d1 c0df663 7d9b5ea 39b6848 0159c7e 7d763f3 1b44f08 d277880 9328a71 9ba4bc2 02798cb" \
  sh performance-audit/run-versions.sh $B 4.6.2 2 $B/src/Luminescence_0.9.25.tar.gz

# covr measuring its own coverage at the commits around #668, #682 and #711
sh performance-audit/bench-self.sh $B 4.6.2 2 v3.6.5 c0df663^ c0df663 39b6848^ 39b6848 d277880^ d277880 HEAD

# Phases on main, with a profile of one more instrumented test run;
# the JIT and branch counts
L=$B/lib/4.6.2
for p in $PKGS; do
  R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
    performance-audit/bench-phases.R $B $p 2 $B/out/phases
  R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
    performance-audit/bench-child-variants.R $p 2 $B/out/variants/$(basename $p .tar.gz).rds
done

# Microbenchmarks and profiles (Luminescence coverage and trace from the phases)
R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
  performance-audit/microbench.R $B/out/phases/Luminescence-trace.rds   # also on 4.3.3, 4.4.3
R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
  performance-audit/microbench-post.R $B/out/phases/Luminescence-coverage.rds
R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
  performance-audit/microbench-parse.R $B/out/phases/Luminescence-coverage.rds
R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
  performance-audit/profile-post.R $B/out/phases/Luminescence-coverage.rds $B/out/profiles/Luminescence
R_LIBS=$L/covr-main:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file \
  performance-audit/diagnose-parse-fallback.R $B/src/Luminescence_0.9.25.tar.gz
for sha in d277880 9328a71; do for p in $PKGS; do
  R_LIBS=$L/covr-$sha:$L/deps /opt/R/4.6.2/bin/Rscript --no-init-file performance-audit/trace-size.R $p
done; done

# Tables
Rscript --vanilla performance-audit/summarise.R $B > performance-audit/results/summary.md
Rscript --vanilla performance-audit/summarise-profile.R $B/out/phases/Luminescence-child.Rprof 30
```

| Script | What it does |
|----|----|
| `setup.R`, `setup.sh` | Dependency and per-version covr libraries for each R version |
| `setup-commits.sh` | covr at given commits |
| `run-versions.sh`, `bench-versions.R` | Time [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) with main-process steps measured by [`trace()`](https://rdrr.io/r/base/trace.html) (Rprof only samples CPU time, so it misses waiting for the install and test processes), then the post-processing functions |
| `bench-phases.R`, `phase-child.R` | Each phase of [`package_coverage()`](https://covr.r-lib.org/dev/reference/package_coverage.md) on main and the uninstrumented baseline, peak RSS, counts, `if` evaluations, and a profile of the test process |
| `bench-child-variants.R` | Tests with the JIT on and off, instrumented and not |
| `bench-self.sh` | covr’s own coverage through `shim_package.sh` |
| `microbench.R` | [`count()`](https://covr.r-lib.org/dev/reference/count.md) and alternatives, trace serialization |
| `microbench-post.R` | `traced_files()`, `non_code_lines()` and [`report()`](https://covr.r-lib.org/dev/reference/report.md) with prototypes |
| `microbench-parse.R` | Parse data with and without token text |
| `profile-post.R`, `summarise-profile.R` | Profiles of the post-processing functions |
| `diagnose-parse-fallback.R` | Counts fallbacks to the slow [`getParseData()`](https://rdrr.io/r/utils/getParseData.html) path |
| `trace-size.R` | Size of the trace files |
| `summarise.R` | The tables in `results/summary.md` |
