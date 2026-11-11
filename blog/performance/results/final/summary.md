| Package | covr 3.6.5 | covr 4.0.0 | Speedup | Runs |
|---|---|---|---|---|
| digest | 2.6 s | 2.4 s | 1.1x | 3 |
| forcats | 4.1 s | 4.2 s | 1.0x | 3 |
| purrr | 9.6 s | 8.8 s | 1.1x | 3 |
| distributional | 10.1 s | 9.3 s | 1.1x | 3 |
| checkmate | 11.5 s | 10.8 s | 1.1x | 3 |
| tidyr | 17.0 s | 15.5 s | 1.1x | 3 |
| roxygen2 | 17.2 s | 13.5 s | 1.3x | 3 |
| posterior | 21.5 s | 17.4 s | 1.2x | 3 |
| testthat | 27.5 s | 21.3 s | 1.3x | 3 |
| devtools | 29.6 s | 27.8 s | 1.1x | 3 |
| lintr | 52.6 s | 40.4 s | 1.3x | 3 |
| dplyr | 53.4 s | 46.8 s | 1.1x | 3 |
| cli | 66.1 s | 32.5 s | 2.0x | 3 |
| targets | 66.5 s | 37.9 s | 1.8x | 3 |
| ggdist | 70.5 s | 60.7 s | 1.2x | 3 |
| quanteda | 81.5 s | 69.4 s | 1.2x | 3 |
| recipes | 85.8 s | 78.6 s | 1.1x | 3 |
| data.table | 95.8 s | 48.7 s | 2.0x | 3 |
| igraph | 101.5 s | 76.1 s | 1.3x | 3 |
| ggplot2 | 139.8 s | 85.0 s | 1.6x | 3 |
| collapse | 142.5 s | 134.5 s | 1.1x | 3 |
| sf | 158.0 s | 155.3 s | 1.0x | 3 |
| Luminescence | 183.4 s | 112.3 s | 1.6x | 3 |
| mlr3 | fails after 707.5 s | 252.9 s | — | 3 |
| insight | 714.8 s | 681.7 s | 1.0x | 3 |
| future | fails after 1,069.6 s | 252.0 s | — | 3 |
| languageserver | — | 738.1 s | — | 3 |

| Package | `report()` 3.6.5 | `report()` 4.0.0 | Peak memory 3.6.5 | Peak memory 4.0.0 |
|---|---|---|---|---|
| digest | 18.0 s | 0.3 s | 388 MB | 148 MB |
| forcats | 1.0 s | 0.2 s | 140 MB | 97 MB |
| purrr | 7.4 s | 0.3 s | 320 MB | 130 MB |
| distributional | 9.6 s | 0.3 s | 359 MB | 151 MB |
| checkmate | 4.8 s | 0.3 s | 295 MB | 140 MB |
| tidyr | 5.5 s | 0.2 s | 293 MB | 135 MB |
| roxygen2 | 9.5 s | 0.4 s | 333 MB | 154 MB |
| posterior | 15.2 s | 0.3 s | 395 MB | 158 MB |
| testthat | 40.7 s | 0.5 s | 562 MB | 198 MB |
| devtools | 2.9 s | 0.2 s | 283 MB | 125 MB |
| lintr | 23.6 s | 0.5 s | 440 MB | 155 MB |
| dplyr | 31.8 s | 0.5 s | 526 MB | 157 MB |
| cli | 81.0 s | 0.6 s | 715 MB | 200 MB |
| targets | 51.9 s | 0.8 s | 611 MB | 181 MB |
| ggdist | 17.6 s | 0.3 s | 471 MB | 162 MB |
| quanteda | 22.6 s | 0.5 s | 608 MB | 179 MB |
| recipes | 56.1 s | 0.6 s | 864 MB | 208 MB |
| data.table | 71.5 s | 0.9 s | 655 MB | 242 MB |
| igraph | — | 9.8 s | — | 1,116 MB |
| ggplot2 | 111.9 s | 0.8 s | 1,055 MB | 246 MB |
| collapse | 116.7 s | 1.2 s | 875 MB | 251 MB |
| sf | 37.2 s | 0.5 s | 609 MB | 202 MB |
| Luminescence | 273.0 s | 1.2 s | 1,194 MB | 310 MB |
| mlr3 | — | 0.4 s | — | 187 MB |
| insight | 184.7 s | 1.0 s | 1,214 MB | 289 MB |
| future | — | 0.4 s | — | 163 MB |
| languageserver | — | 0.9 s | — | 227 MB |

Individual runs (seconds of `package_coverage()`; NA = failed):

- digest, 3.6.5: 2.7, 2.6, 2.5 (coverage 77.7%)
- digest, 9ea0453: 2.4, 2.3, 2.4 (coverage 78.3%)
- forcats, 3.6.5: 3.9, 4.1, 4.4 (coverage 99.6%)
- forcats, 9ea0453: 5.3, 4.0, 4.2 (coverage 99.3%)
- purrr, 3.6.5: 9.3, 9.6, 9.8 (coverage 94.4%)
- purrr, 9ea0453: 8.8, 8.7, 9.1 (coverage 94.4%)
- distributional, 3.6.5: 11.4, 9.8, 10.1 (coverage 76.1%)
- distributional, 9ea0453: 11.0, 9.3, 8.8 (coverage 75.3%)
- checkmate, 3.6.5: 11.4, 11.5, 12.4 (coverage 96.9%)
- checkmate, 9ea0453: 10.8, 10.6, 11.3 (coverage 96.5%)
- tidyr, 3.6.5: 17.0, 15.8, 17.0 (coverage 99.1%)
- tidyr, 9ea0453: 15.0, 15.5, 16.3 (coverage 98.9%)
- roxygen2, 3.6.5: 17.5, 16.1, 17.2 (coverage 94.8%)
- roxygen2, 9ea0453: 14.9, 12.5, 13.5 (coverage 94.8%)
- posterior, 3.6.5: 21.3, 23.2, 21.5 (coverage 95.3%)
- posterior, 9ea0453: 18.9, 16.8, 17.4 (coverage 95.2%)
- testthat, 3.6.5: 27.5, 28.5, 27.5 (coverage 66.9%)
- testthat, 9ea0453: 20.9, 21.3, 21.4 (coverage 66.7%)
- devtools, 3.6.5: 30.1, 29.6, 29.6 (coverage 44.0%)
- devtools, 9ea0453: 27.8, 28.6, 27.1 (coverage 43.4%)
- lintr, 3.6.5: 52.6, 51.6, 53.4 (coverage 99.0%)
- lintr, 9ea0453: 40.0, 40.4, 40.6 (coverage 99.1%)
- dplyr, 3.6.5: 50.2, 53.4, 53.5 (coverage 91.8%)
- dplyr, 9ea0453: 45.9, 46.8, 48.3 (coverage 91.9%)
- cli, 3.6.5: 65.5, 66.2, 66.1 (coverage 75.6%)
- cli, 9ea0453: 32.7, 32.5, 32.1 (coverage 75.4%)
- targets, 3.6.5: 66.5, 66.8, 66.3 (coverage 88.7%)
- targets, 9ea0453: 36.8, 38.9, 37.9 (coverage 88.8%)
- ggdist, 3.6.5: 70.4, 70.5, 70.5 (coverage 97.8%)
- ggdist, 9ea0453: 61.7, 60.7, 59.9 (coverage 97.6%)
- quanteda, 3.6.5: 81.5, 81.4, 82.7 (coverage 96.8%)
- quanteda, 9ea0453: 69.5, 68.7, 69.4 (coverage 96.7%)
- recipes, 3.6.5: 85.8, 86.7, 85.7 (coverage 95.2%)
- recipes, 9ea0453: 79.0, 77.6, 78.6 (coverage 95.2%)
- data.table, 3.6.5: 95.8, 95.8, 95.9 (coverage 98.4%)
- data.table, 9ea0453: 48.7, 50.8, 48.4 (coverage 98.4%)
- igraph, 3.6.5: 100.8, 102.2 (coverage 47.8%)
- igraph, 9ea0453: 76.4, 76.1, 75.1 (coverage 50.3/50.2%)
- ggplot2, 3.6.5: 139.8, 140.5, 138.7 (coverage 83.7%)
- ggplot2, 9ea0453: 83.8, 87.3, 85.0 (coverage 82.6%)
- collapse, 3.6.5: 142.5, 143.0, 142.4 (coverage 75.0%)
- collapse, 9ea0453: 134.8, 134.4, 134.5 (coverage 75.0%)
- sf, 3.6.5: 166.8, 157.5, 158.0 (coverage 50.6%)
- sf, 9ea0453: 163.5, 155.3, 155.2 (coverage 50.2%)
- Luminescence, 3.6.5: 181.9, 183.4, 185.5 (coverage 90.2%)
- Luminescence, 9ea0453: 109.8, 116.0, 112.3 (coverage 89.9%)
- mlr3, 3.6.5: NA, NA, NA (coverage none)
- mlr3, 9ea0453: 252.9, 257.2, 250.2 (coverage 91.5%)
- insight, 3.6.5: 715.9, 714.8, 708.7 (coverage 64.3%)
- insight, 9ea0453: 681.7, 682.2, 678.0 (coverage 63.7%)
- future, 3.6.5: NA, NA, NA (coverage none)
- future, 9ea0453: 252.0, 251.7, 252.9 (coverage 81.4%)
- languageserver, 9ea0453: 738.0, 738.1, 742.7 (coverage 91.4%)
