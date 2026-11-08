#' Create a coverage badge
#'
#' Write an SVG badge showing the percent coverage, in the style of the badges
#' made by Codecov and shields.io, so a README can show the coverage of a
#' package without uploading it to a coverage service. The badge is made
#' locally and doesn't need a network connection.
#'
#' The coverage is that of [percent_coverage()], rounded down to a whole
#' percent so that only fully covered code shows 100%. The badge is green for
#' coverage of 90% or more, yellow for 75% or more and red below that, the
#' same thresholds used by [report()]. Coverage without any lines of code,
#' such as that of a package with no R code, shows as `unknown` on a gray
#' badge.
#'
#' The badge is a plain file, so on a continuous integration service it needs
#' to be stored somewhere that the README can link to, e.g. committed to a
#' separate branch of the repository. See the README of covr for an example
#' GitHub Actions workflow.
#'
#' @param cov the coverage object returned from [package_coverage()]
#' @param filename the name of the SVG file
#' @param label the text on the left side of the badge
#' @return The lines of the SVG file, invisibly.
#' @examples
#' cov <- code_coverage(
#'   "f <- function(x) {\n  y <- x + 1\n  if (y > 0) {\n    'yes'\n  } else {\n    'no'\n  }\n}",
#'   "f(1)"
#' )
#' tmp <- tempfile(fileext = ".svg")
#' to_badge(cov, tmp)
#' cat(readLines(tmp), sep = "\n")
#' @export
to_badge <- function(cov, filename = "coverage.svg", label = "coverage") {
  if (!is.character(label) || length(label) != 1 || is.na(label)) {
    covr_abort("{.arg label} must be a single string.")
  }
  label <- enc2utf8(label)

  percent <- percent_coverage(cov)
  if (is.nan(percent)) {
    value <- "unknown"
  } else {
    value <- paste0(floor(percent), "%")
  }

  out <- badge_svg(label, value, badge_color(percent))

  writeLines(out, filename, useBytes = TRUE)

  invisible(out)
}

badge_color <- function(percent) {
  if (is.nan(percent)) {
    return("#9f9f9f")
  }
  if (percent >= 90) {
    return("#4c1")
  }
  if (percent >= 75) {
    return("#dfb317")
  }
  "#e05d44"
}

# A flat badge with `label` on a gray background on the left and `value` on a
# background of `color` on the right.
badge_svg <- function(label, value, color) {
  label_text <- badge_text_width(label)
  value_text <- badge_text_width(value)
  label_width <- ceiling(label_text) + 10
  value_width <- ceiling(value_text) + 10
  width <- label_width + value_width

  text <- function(x, y, string, text_width, shadow = FALSE) {
    sprintf(
      '<text%s x="%s" y="%s"%s textLength="%s">%s</text>',
      if (shadow) ' aria-hidden="true"' else "",
      badge_number(x),
      y,
      if (shadow) ' fill="#010101" fill-opacity=".3"' else "",
      badge_number(text_width),
      xml_escape(string)
    )
  }
  label_x <- label_width / 2
  value_x <- label_width + value_width / 2
  title <- xml_escape(paste0(label, ": ", value))

  c(
    sprintf(
      '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="20" role="img" aria-label="%s">',
      width,
      title
    ),
    sprintf("<title>%s</title>", title),
    '<linearGradient id="s" x2="0" y2="100%">',
    '<stop offset="0" stop-color="#bbb" stop-opacity=".1"/>',
    '<stop offset="1" stop-opacity=".1"/>',
    "</linearGradient>",
    '<clipPath id="r">',
    sprintf('<rect width="%s" height="20" rx="3" fill="#fff"/>', width),
    "</clipPath>",
    '<g clip-path="url(#r)">',
    sprintf('<rect width="%s" height="20" fill="#555"/>', label_width),
    sprintf(
      '<rect x="%s" width="%s" height="20" fill="%s"/>',
      label_width,
      value_width,
      color
    ),
    sprintf('<rect width="%s" height="20" fill="url(#s)"/>', width),
    "</g>",
    '<g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="11">',
    text(label_x, 15, label, label_text, shadow = TRUE),
    text(label_x, 14, label, label_text),
    text(value_x, 15, value, value_text, shadow = TRUE),
    text(value_x, 14, value, value_text),
    "</g>",
    "</svg>"
  )
}

badge_number <- function(x) {
  format(round(x, 1), nsmall = 0, scientific = FALSE, trim = TRUE)
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

# The width of `x` in pixels in 11px Verdana, the font of the badge. The text
# elements set `textLength` to this, so the text fits the badge even if it is
# shown in another font.
badge_text_width <- function(x) {
  codes <- utf8ToInt(enc2utf8(x))
  ascii <- codes >= 32 & codes <= 126
  widths <- rep(verdana_widths[["m"]], length(codes))
  widths[ascii] <- verdana_widths[codes[ascii] - 31]
  sum(widths)
}

# Advance widths of the printable ASCII characters (32 to 126) in Verdana at
# 11px, from the font's hmtx table.
# fmt: skip
verdana_widths <- stats::setNames(
  c(
    3.87, 4.33, 5.05, 9.00, 6.99, 11.84, 7.99, 2.95, 5.00, 5.00, 6.99, 9.00,
    4.00, 5.00, 4.00, 5.00, 6.99, 6.99, 6.99, 6.99, 6.99, 6.99, 6.99, 6.99,
    6.99, 6.99, 5.00, 5.00, 9.00, 9.00, 9.00, 6.00, 11.00, 7.52, 7.54, 7.68,
    8.48, 6.96, 6.32, 8.53, 8.27, 4.63, 5.00, 7.62, 6.12, 9.27, 8.23, 8.66,
    6.63, 8.66, 7.65, 7.52, 6.78, 8.05, 7.52, 10.88, 7.54, 6.77, 7.54, 5.00,
    5.00, 5.00, 9.00, 6.99, 6.99, 6.61, 6.85, 5.73, 6.85, 6.55, 3.87, 6.85,
    6.96, 3.02, 3.79, 6.51, 3.02, 10.70, 6.96, 6.68, 6.85, 6.85, 4.69, 5.73,
    4.33, 6.96, 6.51, 9.00, 6.51, 6.51, 5.78, 6.98, 5.00, 6.98, 9.00
  ),
  strsplit(intToUtf8(32:126), "")[[1]]
)
