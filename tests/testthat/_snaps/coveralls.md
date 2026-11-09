# coveralls prints the coverage unless quiet

    Code
      res <- coveralls(coverage = cov, quiet = FALSE)
    Message
      TestS4 Coverage: 100.00%
      R/TestS4.R: 100.00%

# coveralls errors if Coveralls reports an error

    Code
      coveralls(coverage = cov)
    Condition
      Error:
      ! Can't upload coverage to Coveralls.
      x Bad repo token

