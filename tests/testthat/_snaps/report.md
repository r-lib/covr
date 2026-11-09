# covr.report_colors is validated (#529)

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must contain valid R colors.
      x Can't find color "notacolor".

---

    Code
      file_report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must contain valid R colors.
      x Can't find color "notacolor".

# report() and file_report() require htmltools

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `report()` requires the htmltools package.
      i Install it with `install.packages("htmltools")`.

---

    Code
      file_report(cov, browse = FALSE)
    Condition
      Error:
      ! `report()` requires the htmltools package.
      i Install it with `install.packages("htmltools")`.

# addin_report() reports the coverage of the active project

    Code
      addin_report()
    Message
      Calculating test coverage for TestS4...

# addin_report() uses the working directory without a project

    Code
      addin_report()
    Message
      Calculating test coverage for TestS4...

