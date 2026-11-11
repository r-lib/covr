# A fixture for the reports, with an `if`/`else` with one branch taken, an
# `if` without `else`, an `if` with both branches taken and a `switch()` with
# an arm that falls through.
report_fixture <- paste(
  collapse = "\n",
  c(
    "sign_of <- function(x) {",
    "  if (x > 0) {",
    "    \"positive\"",
    "  } else {",
    "    \"negative\"",
    "  }",
    "}",
    "maybe <- function(x) {",
    "  if (x) \"yes\"",
    "  \"done\"",
    "}",
    "both <- function(x) if (x) 1 else 2",
    "describe <- function(x) {",
    "  switch(x, a = , b = \"early\", z = \"late\")",
    "}"
  )
)

report_fixture_tests <- paste(
  collapse = "\n",
  c(
    "sign_of(1)",
    "maybe(FALSE)",
    "both(TRUE)",
    "both(FALSE)",
    "describe(\"a\")",
    "describe(\"q\")"
  )
)

# The HTML of `report_html(cov)`, with the temporary file of `code_coverage()`
# renamed to `source.R`, so it can be compared with a snapshot.
report_snapshot_html <- function(cov, fun = report_html) {
  html <- htmltools::renderTags(fun(cov))$html
  for (file in unique(display_name(cov))) {
    html <- gsub(file, "source.R", html, fixed = TRUE)
  }
  strsplit(html, "\n", fixed = TRUE)[[1]]
}
