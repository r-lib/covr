# diff_coverage() counts uncommitted and untracked changes

    Code
      print(res)
    Output
      Changed lines: 4 code lines, 3 covered (75.00%)
      R/a.R: 1 missed  6

# diff_coverage() works for a package in a subdirectory

    Code
      print(res)
    Output
      Changed lines: 1 code lines, 0 covered (0.00%)
      R/a.R: 1 missed  2

# diff_coverage() reports when no code changed

    Code
      print(diff_coverage(cov, base = "main"))
    Output
      No changed code lines.

# diff_coverage() prints separate ranges for missed lines split by code

    Code
      print(res)
    Output
      Changed lines: 2 code lines, 0 covered (0.00%)
      R/a.R: 2 missed  3, 7

# diff_coverage() reports branches on changed lines

    Code
      print(res)
    Output
      Changed lines: 5 code lines, 3 covered (60.00%)
      Changed branches: 9, 4 taken (44.44%)
      R/a.R: 1 missed  5  missed branches 2 FALSE, 5 b, 5 <no match>
      R/b.R: 1 missed  5

# diff_coverage() only counts branches on changed lines

    Code
      print(res)
    Output
      Changed lines: 1 code lines, 1 covered (100.00%)

# print.covr_diff_coverage caps ranges and branches per file

    Code
      print(res)
    Output
      Changed lines: 21 code lines, 0 covered (0.00%)
      Changed branches: 24, 12 taken (50.00%)
      R/a.R: 21 missed  1, 3, 5, 7, 9, 11, 13, 15, 17, 19, ... (11 more)  missed branches 1 FALSE, 3 FALSE, 5 FALSE, 7 FALSE, 9 FALSE, 11 FALSE, 13 FALSE, 15 FALSE, 17 FALSE, 19 FALSE, ... (2 more)

