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

