# it errors if the upload fails, but only warns on 429 and 5xx

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Failed to upload coverage to codecov.io. Client error: (400) Bad Request
      Missing repository upload token

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Failed to upload coverage to codecov.io. Client error: (429) Too Many Requests (RFC 6585)
      Rate limit reached

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Failed to upload coverage to codecov.io. Server error: (503) Service Unavailable
      Service unavailable

