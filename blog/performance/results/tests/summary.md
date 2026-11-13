| Package | Without coverage | covr 3.6.5 | covr 4.0.0 | 3.6.5 / without | 4.0.0 / without |
|---|---|---|---|---|---|
| digest | 0.4 s | 1.5 s | 1.5 s | 3.41× | 3.53× |
| forcats | 2.4 s | 3.5 s | 3.6 s | 1.45× | 1.49× |
| distributional | 5.1 s | 8.6 s | 8.0 s | 1.67× | 1.57× |
| purrr | 6.6 s | 8.1 s* | 8.7 s | 1.22× | 1.30× |
| roxygen2 | 7.4 s | 14.3 s | 12.0 s | 1.92× | 1.61× |
| checkmate | 8.6 s | 10.1 s | 10.6 s | 1.18× | 1.23× |
| posterior | 10.8 s | 20.5 s | 15.7 s | 1.90× | 1.46× |
| tidyr | 11.1 s | 13.7 s* | 14.3 s | 1.23× | 1.28× |
| testthat | 20.1 s | 27.4 s* | 27.0 s | 1.37× | 1.35× |
| cli | 22.9 s | 58.3 s* | 30.6 s | 2.55× | 1.34× |
| devtools | 25.5 s | 26.5 s* | 27.2 s | 1.04× | 1.07× |
| igraph | 27.2 s | 83.6 s | 60.6 s | 3.07× | 2.23× |
| data.table | 28.0 s | 146.1 s | 47.6 s | 5.22× | 1.70× |
| targets | 29.3 s | 64.9 s | 39.4 s | 2.21× | 1.34× |
| lintr | 34.7 s | 51.8 s | 39.5 s | 1.49× | 1.14× |
| dplyr | 39.1 s | 46.4 s* | 44.8 s | 1.19× | 1.15× |
| quanteda | 41.1 s | 72.4 s | 59.6 s | 1.76× | 1.45× |
| ggdist | 52.3 s | 61.0 s* | 56.3 s | 1.17× | 1.08× |
| collapse | 60.2 s | 133.3 s | 126.1 s | 2.22× | 2.10× |
| recipes | 65.4 s | 80.2 s | 73.8 s | 1.23× | 1.13× |
| ggplot2 | 67.2 s | 122.3 s* | 80.0 s | 1.82× | 1.19× |
| Luminescence | 78.6 s | 154.5 s* | 106.8 s | 1.97× | 1.36× |
| sf | 169.5 s | 241.2 s | 180.8 s | 1.42× | 1.07× |
| mlr3 | 177.1 s | 673.3 s* | 247.3 s | 3.80× | 1.40× |
| future | 230.1 s | 1,175.8 s* | 281.5 s | 5.11× | 1.22× |
| languageserver | 546.9 s | — | 737.3 s | — | 1.35× |
| insight | 645.9 s | 671.1 s* | 660.9 s | 1.04× | 1.02× |

Times exclude installing the package; median of the runs. * covr 3.6.5 stopped with an error after the tests, as some tests fail; wall time of the run.
future was run with its tests patched as in futureverse/future#850 (`future-850.patch`).
Packages with failing tests (also without coverage): cli, devtools, dplyr, ggdist, ggplot2, insight, languageserver, Luminescence, purrr, testthat, tidyr 
