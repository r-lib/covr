# coveralls prints the coverage unless quiet

    Code
      res <- coveralls(coverage = cov, quiet = FALSE)
    Message
      TestS4 Coverage: 100.00%
      R/TestS4.R: 100.00%

# coveralls errors if Coveralls doesn't accept the upload

    Code
      coveralls(coverage = cov)
    Condition
      Error:
      ! Can't upload coverage to Coveralls.
      x HTTP 422 Unprocessable Entity.
      i Coveralls replied:
      {"message":"Bad repo token","error":true}

---

    Code
      coveralls(coverage = cov)
    Condition
      Error:
      ! Can't upload coverage to Coveralls.
      x HTTP 500 Internal Server Error.
      i Coveralls replied:
      {"message":"Oops"}

---

    Code
      coveralls(coverage = cov)
    Condition
      Error:
      ! Can't upload coverage to Coveralls.
      x HTTP 502 Bad Gateway.
      i Coveralls replied:
      <html>Bad Gateway</html>

---

    Code
      coveralls(coverage = cov)
    Condition
      Error:
      ! Can't upload coverage to Coveralls.
      x HTTP 503 Service Unavailable.

