test_that("report_html() lists the files in a sortable table (#316)", {
  skip_if_not_installed("htmltools")

  stats <- data.frame(
    File = c("b.R", "a.R", "c.R"),
    Lines = c(10L, 20L, 5L),
    Relevant = c(4L, 2L, 0L),
    Covered = c(1L, 2L, 0L),
    Missed = c(3L, 0L, 0L),
    `Hits / Line` = c("1", "3", "NaN"),
    Coverage = c("33.33%", "100.00%", "NaN%"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  # The sort keys are read by JavaScript, so need a decimal point
  withr::local_options(OutDec = ",")
  html <- as.character(file_table(stats))

  sorts <- regmatches(html, gregexpr('data-sort="[^"]*"', html))[[1]]
  expect_equal(
    sorts,
    sprintf(
      'data-sort="%s"',
      c(
        "b.R",
        "10",
        "4",
        "1",
        "3",
        "1",
        "33.33",
        "a.R",
        "20",
        "2",
        "2",
        "0",
        "3",
        "100.00",
        "c.R",
        "5",
        "0",
        "0",
        "0",
        "",
        ""
      )
    )
  )
  expect_match(html, "var(--covr-bar-low) 33.33%", fixed = TRUE)
  expect_match(html, "var(--covr-bar-high) 100.00%", fixed = TRUE)
  expect_length(gregexpr("covr-bar-", html, fixed = TRUE)[[1]], 2)
  expect_match(html, '<a href="#" class="covr-file-link">b.R</a>', fixed = TRUE)
})

test_that("report() works with empty coverage (#540)", {
  x <- structure(list(), class = "coverage", package = list(package = "p"))
  data <- to_report_data(x)
  expect_equal(nrow(data$file_stats), 0)
  expect_named(
    data$file_stats,
    c(
      "File",
      "Lines",
      "Relevant",
      "Covered",
      "Missed",
      "Hits / Line",
      "Coverage"
    )
  )
  file <- withr::local_tempfile(fileext = ".html")
  report(x, file = file, browse = FALSE)
  expect_true(file.exists(file))
})

test_that("report_html() can include several reports in a document (#316)", {
  skip_if_not_installed("htmltools")

  count <- function(x, pattern) {
    lengths(regmatches(x, gregexpr(pattern, x, fixed = TRUE)))
  }
  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- file.path(withr::local_tempdir(), "page.html")
  htmltools::save_html(
    htmltools::tagList(report_html(cov), report_html(cov)),
    file
  )
  html <- paste(readLines(file), collapse = "\n")
  head <- sub("</head>.*", "", html)

  expect_equal(count(html, 'class="covr-report covr-colors-'), 2)
  ids <- regmatches(html, gregexpr(' id="[^"]+"', html))[[1]]
  expect_equal(anyDuplicated(ids), 0)

  # The scripts and styles are included once, in the <head>
  for (asset in c("theme.js", "report.js", "report.css")) {
    expect_equal(count(head, paste0("/", asset, '"')), 1)
  }

  # Bootstrap and jQuery would replace the versions used by the document
  expect_no_match(html, "bootstrap|jquery|datatables", ignore.case = TRUE)
})

test_that("report_html() keeps the colors of each report in a document (#316)", {
  skip_if_not_installed("htmltools")

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  withr::local_options(covr.report_colors = NULL)
  default <- report_html(cov)
  withr::local_options(
    covr.report_colors = c(covered = "#0072B2", missed = "#E69F00")
  )
  custom <- report_html(cov)
  html <- htmltools::renderTags(htmltools::tagList(default, custom))$html

  reports <- regmatches(html, gregexpr('class="covr-report [^"]+"', html))[[1]]
  expect_length(unique(reports), 2)
  classes <- sub('class="covr-report ([^"]+)"', "\\1", reports)
  palettes <- list(
    c("rgba(95,151,68,0.3)", "rgba(185,73,71,0.3)", "#edfde7"),
    c("rgba(0,114,178,0.3)", "rgba(230,159,0,0.3)", "#e0eef6")
  )
  for (i in 1:2) {
    styles <- regmatches(
      html,
      gregexpr(
        paste0("\\.covr-report\\.", classes[[i]], "[^{]*\\{[^}]*\\}"),
        html
      )
    )[[1]]
    for (color in palettes[[i]]) {
      expect_match(styles, color, fixed = TRUE, all = FALSE)
    }
    for (color in palettes[[3 - i]]) {
      expect_no_match(styles, color, fixed = TRUE)
    }
  }
})

test_that("report_html() styles only the report (#316)", {
  skip_if_not_installed("htmltools")
  # shim_package.sh renames `covr` in this pattern, but not in report.css, when
  # covr measures its own coverage
  skip_if(identical(Sys.getenv("R_COVR"), "true"), "Running under covr")

  css <- paste(
    c(
      readLines(system.file("www/report.css", package = "covr")),
      report_colors_css(report_colors(NULL), branches = TRUE)$children[[1]]
    ),
    collapse = "\n"
  )
  css <- gsub("(?s)/\\*.*?\\*/", "", css, perl = TRUE)
  selectors <- regmatches(css, gregexpr("[^{}]+(?=\\{)", css, perl = TRUE))
  selectors <- trimws(unlist(strsplit(selectors[[1]], ",")))
  unscoped <- selectors[
    !grepl("^(html\\.covr-dark )?\\.covr-report\\b", selectors)
  ]
  expect_equal(unscoped, character())
})

test_that("report() uses the default colors (#529)", {
  skip_if_not_installed("htmltools")
  withr::local_options(covr.report_colors = NULL)

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- report(cov, file = withr::local_tempfile(fileext = ".html"))
  html <- paste(readLines(file), collapse = "\n")

  expect_match(
    html,
    "table tr.covered td{\n  background-color:rgba(95,151,68,0.3)\n}",
    fixed = TRUE
  )
  expect_match(
    html,
    "table tr:hover.missed .num{\n  background-color:rgba(185,73,71,0.7)\n}",
    fixed = TRUE
  )
  expect_match(html, "box-shadow:0 -2px 0 0 #5f9744 inset", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #b94947 inset", fixed = TRUE)
  expect_match(
    html,
    "{\n  --covr-bar-high:#edfde7;\n  --covr-bar-mid:#f9ffe5;\n  --covr-bar-low:#fcece9;\n}",
    fixed = TRUE
  )
  expect_match(
    html,
    "{\n  --covr-bar-high:#374e33;\n  --covr-bar-mid:#2c3a2e;\n  --covr-bar-low:#583234;\n}",
    fixed = TRUE
  )
})

test_that("report() and file_report() use covr.report_colors (#529)", {
  skip_if_not_installed("htmltools")
  withr::local_options(
    covr.report_colors = c(
      covered = "#0072B2",
      missed = "orange",
      partial = "#56B4E9"
    )
  )

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- report(cov, file = withr::local_tempfile(fileext = ".html"))
  html <- paste(readLines(file), collapse = "\n")
  expect_match(html, "background-color:rgba(0,114,178,0.3)", fixed = TRUE)
  expect_match(html, "background-color:rgba(255,165,0,0.3)", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #0072b2 inset", fixed = TRUE)
  expect_match(html, "box-shadow:0 -2px 0 0 #ffa500 inset", fixed = TRUE)
  expect_match(html, "--covr-bar-high:#e0eef6;", fixed = TRUE)
  expect_match(html, "--covr-bar-mid:#ebf6fc;", fixed = TRUE)
  expect_match(html, "--covr-bar-low:#fff4e0;", fixed = TRUE)
  expect_no_match(html, "95,151,68|185,73,71|#5f9744|#b94947|#edfde7|#fcece9")

  file <- file_report(
    cov,
    out_file = withr::local_tempfile(fileext = ".html"),
    browse = FALSE
  )
  html <- paste(readLines(file), collapse = "\n")
  expect_match(html, "background-color:rgba(0,114,178,0.3)", fixed = TRUE)
  expect_match(html, "background-color:rgba(255,165,0,0.3)", fixed = TRUE)
})

test_that("covr.report_colors can set only one color (#529)", {
  colors <- report_colors(c(missed = "#E69F00"))
  expect_equal(colors[, "covered"], c(red = 95, green = 151, blue = 68))
  expect_equal(colors[, "missed"], c(red = 230, green = 159, blue = 0))
  expect_equal(
    coverage_tints(colors),
    c(high = "#edfde7", mid = "#f9ffe5", low = "#fcf3e0")
  )
})

test_that("covr.report_colors can set the partial color (#529)", {
  colors <- report_colors(c(partial = "#E69F00"))
  expect_equal(colnames(colors), c("covered", "missed", "partial"))
  expect_equal(
    coverage_tints(colors),
    c(high = "#edfde7", mid = "#fcf3e0", low = "#fcece9")
  )
  expect_equal(colnames(report_colors(NULL)), c("covered", "missed"))
})

test_that("colorblind_palette sets all three report colors (#751)", {
  colors <- report_colors(colorblind_palette)
  expect_equal(colnames(colors), c("covered", "missed", "partial"))
  expect_equal(rgb_hex(colors[, "partial"]), "#f0e442")
})

test_that("coverage_tints() mixes the colors with the dark background (#563)", {
  expect_equal(
    coverage_tints(report_colors(NULL), dark = TRUE),
    c(high = "#374e33", mid = "#2c3a2e", low = "#583234")
  )
  colors <- report_colors(c(covered = "#0000FF", partial = "#FFFFFF"))
  expect_equal(
    coverage_tints(colors, dark = TRUE),
    c(high = "#151876", mid = "#717376", low = "#583234")
  )
  expect_equal(
    coverage_tints(colors),
    c(high = "#e0e0ff", mid = "#ffffff", low = "#fcece9")
  )
})

test_that("report() and file_report() can switch to a dark theme (#563)", {
  skip_if_not_installed("htmltools")

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  files <- c(
    report(cov, file = withr::local_tempfile(fileext = ".html")),
    file_report(
      cov,
      out_file = withr::local_tempfile(fileext = ".html"),
      browse = FALSE
    )
  )
  for (file in files) {
    html <- paste(readLines(file), collapse = "\n")
    head <- sub("</head>.*", "", html)
    theme_js <- regmatches(
      head,
      regexpr('[^"]+/theme\\.js(?=")', head, perl = TRUE)
    )
    expect_length(theme_js, 1)
    expect_match(
      readLines(file.path(dirname(file), theme_js)),
      "prefers-color-scheme: dark",
      fixed = TRUE,
      all = FALSE
    )
    expect_match(html, "<button[^>]+covr-theme-toggle[^>]+>")
  }
})

test_that("file_report() doesn't load jQuery or Bootstrap", {
  skip_if_not_installed("htmltools")

  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  file <- file_report(
    cov,
    out_file = withr::local_tempfile(fileext = ".html"),
    browse = FALSE
  )
  html <- paste(readLines(file), collapse = "\n")
  expect_no_match(html, "jquery|bootstrap|datatables", ignore.case = TRUE)
  expect_match(html, "covrHljs.highlightBlock", fixed = TRUE)
})

test_that("covr.report_colors is validated (#529)", {
  skip_if_not_installed("htmltools")
  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  local_report_colors <- function(colors) {
    withr::local_options(
      covr.report_colors = colors,
      .local_envir = parent.frame()
    )
  }

  local_report_colors(c("blue", "orange"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(c(covered = "blue", hit = "orange"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(list(covered = "blue"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  local_report_colors(c(covered = "notacolor"))
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  expect_snapshot(file_report(cov, browse = FALSE), error = TRUE)
})

test_that("renderSourceTable() escapes the source and file names", {
  skip_if_not_installed("htmltools")

  data <- list(
    'a"<b>&.R' = data.frame(
      line = 1:4,
      source = c("x <- a < b & \"c\"", "y", "z <- 'q'", "<script>"),
      coverage = c("3", "0", "", "1"),
      stringsAsFactors = FALSE
    )
  )
  html <- as.character(renderSourceTable(data))

  expect_match(html, 'data-file="a&quot;&lt;b&gt;&amp;.R"', fixed = TRUE)
  expect_match(html, "x &lt;- a &lt; b &amp; \"c\"</pre>", fixed = TRUE)
  expect_match(html, "&lt;script&gt;</pre>", fixed = TRUE)
  expect_equal(lengths(regmatches(html, gregexpr("<script>", html))), 1L)
  expect_match(
    html,
    '<tr class="covered"><td class="num">1</td><td class="coverage">3<em>x</em></td>',
    fixed = TRUE
  )
  expect_match(
    html,
    '<tr class="missed"><td class="num">2</td><td class="coverage">!</td>',
    fixed = TRUE
  )
  expect_match(
    html,
    '<tr class="never"><td class="num">3</td><td class="coverage"></td>',
    fixed = TRUE
  )
})

test_that("renderSourceTable() has no rows for an empty file", {
  skip_if_not_installed("htmltools")

  data <- list(
    "empty.R" = data.frame(
      line = integer(),
      source = character(),
      coverage = character()
    )
  )
  html <- as.character(renderSourceTable(data))

  expect_match(html, 'data-file="empty.R"', fixed = TRUE)
  expect_no_match(html, "<tr", fixed = TRUE)
})

test_that("report_html() and file_report_html() are unchanged without branches", {
  skip_if_not_installed("htmltools")
  withr::local_options(covr.report_colors = NULL)

  cov <- code_coverage(report_fixture, report_fixture_tests)
  expect_snapshot(writeLines(report_snapshot_html(cov)))
  expect_snapshot(writeLines(report_snapshot_html(cov, file_report_html)))
})

test_that("report_html() shows the branches taken on each line (#751)", {
  skip_if_not_installed("htmltools")
  withr::local_options(covr.report_colors = NULL)

  cov <- branch_coverage(report_fixture, report_fixture_tests)
  expect_snapshot(writeLines(report_snapshot_html(cov)))
  expect_match(
    report_snapshot_html(cov, file_report_html),
    "<h2>source.R - 57.14% (branches 66.67%)</h2>",
    fixed = TRUE,
    all = FALSE
  )
})

test_that("report_html() colors partly covered lines with the partial color (#751)", {
  skip_if_not_installed("htmltools")
  withr::local_options(
    covr.report_colors = c(covered = "#0072B2", partial = "#56B4E9")
  )

  cov <- branch_coverage(report_fixture, report_fixture_tests)
  html <- report_snapshot_html(cov)
  expect_match(
    html,
    "table tr.partial td{",
    fixed = TRUE,
    all = FALSE
  )
  expect_match(
    html,
    "background-color:rgba(86,180,233,0.3)",
    fixed = TRUE,
    all = FALSE
  )
})

test_that("lines with an untaken branch are partly covered (#751)", {
  type <- c("covered", "covered", "covered", "missed", "missed", "never")
  taken <- c(2L, 1L, 0L, 1L, 0L, 2L)
  total <- c(2L, 2L, 2L, 2L, 2L, 2L)
  expect_equal(
    branch_line_type(type, taken, total),
    c("covered", "partial", "partial", "partial", "missed", "covered")
  )
  expect_equal(
    branch_line_type(
      c("never", "missed", "covered"),
      c(0L, NA, NA),
      c(3L, NA, NA)
    ),
    c("missed", "missed", "covered")
  )
})

test_that("the file list has the percentage of branches taken (#751)", {
  lines <- function(taken, total) {
    data.frame(
      line = 1:2,
      source = c("a", "b"),
      coverage = c("1", "0"),
      taken = taken,
      total = total,
      branches = "",
      stringsAsFactors = FALSE
    )
  }
  stats <- compute_file_stats(list(
    a.R = lines(c(1L, 2L), c(2L, 2L)),
    b.R = lines(c(NA, NA), c(NA, NA))
  ))
  expect_equal(stats$Branches, c("75.00%", ""))
  expect_equal(
    names(sort_file_stats(cbind(stats, File = c("a.R", "b.R")))),
    c(
      "File",
      "Lines",
      "Relevant",
      "Covered",
      "Missed",
      "Hits / Line",
      "Branches",
      "Coverage"
    )
  )
})

test_that("report_html() leaves out the branches of excluded lines (#751)", {
  cov <- branch_coverage(
    c(
      "f <- function(x) {",
      "  if (x) 1 else 2 # nocov",
      "  if (x) 3",
      "}"
    ),
    "f(TRUE)"
  )
  data <- to_report_data(cov)
  expect_equal(data$full[[1]]$total, c(NA, NA, 2L, NA))
  expect_equal(data$branches_overall, 50)
})

test_that("report() and file_report() open the report in the viewer", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")
  cov <- code_coverage("f <- function(x) x + 1\ng <- function() 2", "f(1)")

  opened <- character()
  withr::local_options(viewer = function(url) opened <<- c(opened, url))

  file <- report(
    cov,
    file = withr::local_tempfile(fileext = ".html"),
    browse = TRUE
  )
  expect_equal(opened, file)

  out_file <- file_report(
    cov,
    out_file = withr::local_tempfile(fileext = ".html"),
    browse = TRUE
  )
  expect_equal(opened, c(file, out_file))

  report(cov, file = withr::local_tempfile(fileext = ".html"), browse = FALSE)
  expect_length(opened, 2)
})

test_that("file_report() marks the lines that were not run", {
  skip_if_not_installed("DT")
  skip_if_not_installed("htmltools")
  cov <- code_coverage("f <- function(x) x + 1\ng <- function() 2", "f(1)")

  file <- file_report(
    cov,
    out_file = withr::local_tempfile(fileext = ".html"),
    browse = FALSE
  )
  html <- paste(readLines(file), collapse = "\n")
  expect_match(html, "<tr class=\"missed\">", fixed = TRUE)
  expect_match(html, "<td class=\"coverage\">!</td>", fixed = TRUE)
  expect_match(html, "<td class=\"coverage\">1<em>x</em></td>", fixed = TRUE)
})

test_that("report() and file_report() require htmltools", {
  cov <- code_coverage("f <- function(x) x + 1", "f(1)")
  local_mocked_bindings(is_installed = function(pkg) FALSE)
  expect_snapshot(report(cov, browse = FALSE), error = TRUE)
  expect_snapshot(file_report(cov, browse = FALSE), error = TRUE)
})

test_that("addin_report() reports the coverage of the active project", {
  covered <- NULL
  local_mocked_bindings(
    rstudio_active_project = function() test_path("TestS4"),
    package_coverage = function(path) path,
    report = function(x) covered <<- x
  )
  expect_snapshot(addin_report())
  expect_equal(covered, as_package(test_path("TestS4"))$path)
})

test_that("addin_report() uses the working directory without a project", {
  covered <- NULL
  withr::local_dir(test_path("TestS4"))
  local_mocked_bindings(
    rstudio_active_project = function() NULL,
    package_coverage = function(path) path,
    report = function(x) covered <<- x
  )
  expect_snapshot(addin_report())
  expect_equal(covered, as_package(getwd())$path)
})
