# an invalid covr.report_colors only warns in the console (#529)

    Code
      styles <- console_styles()
    Condition
      Warning:
      `covr.report_colors` must contain valid R colors.
      x Can't find color "notacolor".
      i Using the default colors.

# print.coverage limits the files or functions printed with n

    Code
      print(cov, group = "functions", n = 1)
    Message
      pkg Coverage: 33.33%
      g: 0.00%
      ... and 2 more functions; use `print(x, n = Inf)` to show all
    Code
      print(cov, group = "functions", n = 3)
    Message
      pkg Coverage: 33.33%
      g: 0.00%
      h: 0.00%
      f: 100.00%
    Code
      print(cov, n = 0)
    Message
      pkg Coverage: 33.33%
      ... and 1 more file; use `print(x, n = Inf)` to show all

# print.coverages prints the coverage of each type

    Code
      res <- print(covs)
    Message
      pkg Tests Coverage: 100.00%
      <file>: 100.00%
      
      pkg Examples Coverage: 100.00%
      <file>: 100.00%

# print.coverage lists the missed ranges with missing = TRUE

    Code
      print(cov, missing = TRUE)
    Message
      pkg Coverage: 50.00%
      source.R: 50.00%  missed 3-6, 10, 14
    Code
      print(cov, group = "functions", missing = TRUE)
    Message
      pkg Coverage: 50.00%
      g: 0.00%  missed 14
      f: 50.00%  missed 3-6, 10
      h: 100.00%
    Code
      print(cov, missing = FALSE)
    Message
      pkg Coverage: 50.00%
      source.R: 50.00%
    Code
      print(cov, by = "expression", missing = TRUE)
    Message
      pkg Coverage: 50.00%
      source.R: 50.00%

# print.coverage lists the missed branches with missing = TRUE

    Code
      print(cov, missing = TRUE)
    Message
      pkg Coverage: 25.00% (branches 33.33%)
      source.R: 25.00%  missed 2, 6, 9  missed branches 2 FALSE, 3 FALSE, 6 b, 6 <no match>
    Code
      print(cov, group = "functions", missing = TRUE)
    Message
      pkg Coverage: 25.00% (branches 33.33%)
      g: 0.00%  missed 6  missed branches 6 b, 6 <no match>
      h: 0.00%  missed 9
      f: 50.00%  missed 2  missed branches 2 FALSE, 3 FALSE
    Code
      print(cov)
    Message
      pkg Coverage: 25.00% (branches 33.33%)
      source.R: 25.00%

# print.coverage caps the missed ranges and branches per row

    Code
      print(cov, missing = TRUE)
    Message
      pkg Coverage: 33.33% (branches 50.00%)
      source.R: 33.33%  missed 2, 4, 8, 10, 14, 16, 20, 22, 26, 28, ... (18 more)  missed branches 2 FALSE, 3 TRUE, 8 FALSE, 9 TRUE, 14 FALSE, 15 TRUE, 20 FALSE, 21 TRUE, 26 FALSE, 27 TRUE, ... (18 more)

---

    Code
      print(cov, missing = TRUE)
    Message
      pkg Coverage: 33.33% (branches 50.00%)
      source.R: 33.33%  missed 2, 4, ... (26 more)  missed branches 2 FALSE, 3 TRUE, ... (26 more)

---

    Code
      print(cov, missing = TRUE)
    Message
      pkg Coverage: 33.33% (branches 50.00%)
      source.R: 33.33%  missed 2, 4, 8, 10, 14, 16, 20, 22, 26, 28, 32, 34, 38, 40, 44, 46, 50, 52, 56, 58, 62, 64, 68, 70, 74, 76, 80, 82  missed branches 2 FALSE, 3 TRUE, 8 FALSE, 9 TRUE, 14 FALSE, 15 TRUE, 20 FALSE, 21 TRUE, 26 FALSE, 27 TRUE, 32 FALSE, 33 TRUE, 38 FALSE, 39 TRUE, 44 FALSE, 45 TRUE, 50 FALSE, 51 TRUE, 56 FALSE, 57 TRUE, 62 FALSE, 63 TRUE, 68 FALSE, 69 TRUE, 74 FALSE, 75 TRUE, 80 FALSE, 81 TRUE

