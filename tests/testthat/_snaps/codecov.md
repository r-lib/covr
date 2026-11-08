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
      ! Can't determine the repository (`owner/repo`) to upload coverage for.
      i Run `codecov()` on a CI service or in a git repository with an `origin` remote.

# it errors if the upload can't be requested, but only warns on 429 and 5xx

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Can't request an upload from Codecov.
      x Client error: (400) Bad Request.
      i Codecov replied:
      Missing repository upload token

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Can't request an upload from Codecov.
      x Client error: (429) Too Many Requests (RFC 6585).
      i Codecov replied:
      Rate limit reached

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Can't request an upload from Codecov.
      x Server error: (503) Service Unavailable.
      i Codecov replied:
      Service unavailable

# it only sends coverage if an upload was requested

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Can't find an upload location in Codecov's reply.
      i Codecov replied:
      {"url": "https://app.codecov.io"}

# it errors if the coverage can't be sent, but only warns on 429 and 5xx

    Code
      codecov(coverage = cov)
    Condition
      Error:
      ! Can't send coverage to Codecov.
      x Client error: (403) Forbidden.
      i Codecov replied:
      <Error><Code>AccessDenied</Code></Error>

---

    Code
      res <- codecov(coverage = cov, quiet = FALSE)
    Message
      TestS4 Coverage: 100.00%
      R/TestS4.R: 100.00%
    Condition
      Warning:
      Can't send coverage to Codecov.
      x Client error: (429) Too Many Requests (RFC 6585).
      i Codecov replied:
      Rate limit reached

---

    Code
      res <- codecov(coverage = cov)
    Condition
      Warning:
      Can't send coverage to Codecov.
      x Server error: (503) Service Unavailable.
      i Codecov replied:
      Service unavailable

