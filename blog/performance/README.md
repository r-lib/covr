# Benchmark data for the covr performance work

Raw results and scripts behind the performance work in #733, #734 and #740, kept for the release blog post. The audit itself, with its scripts and summaries, is in `performance-audit.md` and `performance-audit/`. This directory holds the data that isn't there, plus the runs made after the audit.

All timings are wall clock on WSL2 (Intel i7-12700KF, 20 threads, 16 GB) unless noted, and use R 4.6.2. The packages are CRAN source tarballs, and tests run with `NOT_CRAN=true`. The libraries and tarballs aren't kept; `performance-audit/setup.R` and `scripts/deps-more.R` rebuild them.

## covr 3.6.5 vs 4.0.0

The comparison in the release blog post (`results/release/`, `scripts/run-release.sh`, `scripts/bench-release.R`, summarised by `scripts/summarise-release.R`). covr 3.6.5 from CRAN against main at `aaa75cf` (#740 merged), 3 interleaved runs. Both run the tests the same way, as covr 3.6.5 has no `allow_failures`: `package_coverage(type = "none", code = ...)` with `testthat::test_dir(stop_on_failure = FALSE)`, or for data.table each script in `tests/` sourced in turn. `report()` is timed in the first run only, and the peak memory is that of the main process after `report()`.

| Package | covr 3.6.5 | covr 4.0.0 | Speedup |
|---|---|---|---|
| forcats 1.0.1 | 4.8 s | 4.9 s | 1.0x |
| checkmate 2.3.4 | 13.5 s | 13.4 s | 1.0x |
| devtools 2.5.2 | 30.6 s | 28.2 s | 1.1x |
| lintr 3.4.0 | 68.6 s | 48.2 s | 1.4x |
| dplyr 1.2.1 | 58.6 s | 53.9 s | 1.1x |
| data.table 1.18.6.1 | 105.8 s | 57.6 s | 1.8x |
| Luminescence 0.9.25 | 198.7 s | 125.5 s | 1.6x |

| Package | `report()` 3.6.5 | `report()` 4.0.0 | Peak memory 3.6.5 | Peak memory 4.0.0 |
|---|---|---|---|---|
| forcats | 1.3 s | 0.2 s | 137 MB | 110 MB |
| checkmate | 6.2 s | 0.5 s | 276 MB | 135 MB |
| devtools | 3.5 s | 0.3 s | 280 MB | 121 MB |
| lintr | 27.1 s | 0.8 s | 435 MB | 145 MB |
| dplyr | 38.0 s | 0.9 s | 528 MB | 171 MB |
| data.table | 87.2 s | 2.9 s | 648 MB | 233 MB |
| Luminescence | 350.7 s | 3.2 s | 1,215 MB | 330 MB |

The runs are noisy on this shared machine (e.g. lintr with 4.0.0: 48.2, 67.6 and 46.4 s); `summarise-release.R` lists them all.

## Headline numbers

`package_coverage(type = "tests")`, median of 2 interleaved runs (`results/more/`, `scripts/run-more.sh`):

| Package | #734 (count in C) | #740 (instrument once after install) | #740, not compiled |
|---|---|---|---|
| forcats 1.0.1 | 4.8 s | 4.8 s | 4.5 s |
| checkmate 2.3.4 | 12.4 s | 12.1 s | 11.2 s |
| devtools 2.5.2 | 27.4 s | 28.0 s | 26.6 s |
| lintr 3.4.0 | 50.3 s | 46.6 s | 48.6 s |
| dplyr 1.2.1 | 59.4 s | 54.4 s | 52.9 s |
| data.table 1.18.6.1 | 110.4 s | 58.2 s | 79.3 s |
| Luminescence 0.9.25 | 150.8 s | 121.8 s | 135.1 s |
| covr's own coverage | 135.3 s | 102.9 s | — |

`report()` on Luminescence takes 354 s on main before #733 and 4.1 s after (`results/phases-*`).

Earlier history, from `performance-audit.md` (Luminescence, `package_coverage()` with testthat code):

| covr | R 4.3.3 | R 4.4.3 | R 4.6.2 |
|---|---|---|---|
| 3.5.1 | 180 s | — | can't load |
| 3.6.4 | 197 s | 2,517 s | can't load |
| 3.6.5 | 187 s | 204 s | 217 s |
| main before #733 | 171 s | 179 s | 186 s |

## Contents

| Path | What | Produced by |
|---|---|---|
| `results/versions/` | covr 3.5.1–3.6.5 and main × forcats, checkmate, Luminescence × R 4.3.3, 4.4.3, 4.6.2 (`.rds` per run, `.time` with max RSS, `.log`) | `performance-audit/run-versions.sh`, `bench-versions.R` |
| `results/history/` | Luminescence at each commit on main between 3.6.5 and the audit, and its parent | same, with `OUT_SUBDIR=history` |
| `results/self/` | covr measuring its own coverage around #668, #682 and #711 | `performance-audit/bench-self.sh` |
| `results/phases-main/` | Phase breakdown of `package_coverage()` on main before #733 vs an uninstrumented install and test run | `performance-audit/bench-phases.R` |
| `results/phases-733/` | The same with #733's changes (before #734 and #740) | same |
| `results/variants/` | Instrumented vs plain tests with the JIT on and off; counts of evaluated `if` conditions (branch-coverage cost) | `performance-audit/bench-child-variants.R` |
| `results/ab/` | Interleaved Luminescence test runs: main vs #733 (`ab-main-*`, `ab-int-*`), and #733 vs the C counter (`abc-int-*`, `abc-c-*`) | `scripts/ab-count.sh`, `scripts/abc-count.sh` |
| `results/more/` | The headline table above: 7 packages × #734 (`base`) / #740 (`it`) / #740 not compiled (`itnc`) × 2 runs; each `.rds` holds per-trace counts in `$values` | `scripts/run-more.sh`, `scripts/bench-tests.R` |
| `results/more-self/` | covr's own coverage for the same three builds. The `itnc` runs failed two covr tests that expected compiling; that was fixed later and not re-timed | `scripts/self-more.sh` |
| `results/trace-size.txt` | Trace file sizes before and after #707 | `performance-audit/trace-size.R` |
| `scripts/cform-bench.R`, `cc-hot2.R`, `cc-why2.R`, `cc-nsbind.R` | Microbenchmarks of the counting call forms, e.g. `covr:::count()` 763 ns, `.Call` via `:::` 128 ns, embedded routine 65 ns | run with the covr build to test first in `R_LIBS` |

The builds compared in `results/more/` are:
- `base`: #734 at `2beab73`;
- `it`: #740 at `9486437`;
- `itnc`: the same as `it` with `COVR_INSTALL_COMPILE=false`.
