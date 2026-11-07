# it errors if the upload fails

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Failed to upload coverage to codecov.io. Client error: (400) Bad Request
      Missing repository upload token

