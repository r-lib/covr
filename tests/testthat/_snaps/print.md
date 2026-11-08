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

