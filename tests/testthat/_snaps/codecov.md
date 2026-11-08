# it prints the url of the upload unless quiet

    Code
      res <- codecov(coverage = cov, quiet = FALSE)
    Message
      TestS4 Coverage: 100.00%
      R/TestS4.R: 100.00%
      Coverage uploaded to Codecov: https://app.codecov.io/github/tester/test/commit/abc

# it errors if the repository can't be determined

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Can't determine the repository (`owner/repo`) to upload coverage for. Run `codecov()` on a CI service or in a git repository with an `origin` remote.

# it errors if the upload can't be requested, but only warns on 429 and 5xx

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Failed to request an upload from Codecov. Client error: (400) Bad Request
      Missing repository upload token

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Failed to request an upload from Codecov. Client error: (429) Too Many Requests (RFC 6585)
      Rate limit reached

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Failed to request an upload from Codecov. Server error: (503) Service Unavailable
      Service unavailable

# it only sends coverage if an upload was requested

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Codecov did not return a location to upload the coverage to.
      {"url": "https://app.codecov.io"}

# it errors if the coverage can't be sent, but only warns on 429 and 5xx

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Failed to send coverage to Codecov. Client error: (403) Forbidden
      <Error><Code>AccessDenied</Code></Error>

---

    Code
      res <- codecov(coverage = cov, quiet = FALSE)
    Message
      TestS4 Coverage: 100.00%
      R/TestS4.R: 100.00%
    Condition
      Warning:
      Failed to send coverage to Codecov. Client error: (429) Too Many Requests (RFC 6585)
      Rate limit reached

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Failed to send coverage to Codecov. Server error: (503) Service Unavailable
      Service unavailable

