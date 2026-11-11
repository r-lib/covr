# it writes an SVG badge with the percent coverage

    Code
      writeLines(out)
    Output
      <svg xmlns="http://www.w3.org/2000/svg" width="97" height="20" role="img" aria-label="coverage: 75%">
      <title>coverage: 75%</title>
      <linearGradient id="s" x2="0" y2="100%">
      <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
      <stop offset="1" stop-opacity=".1"/>
      </linearGradient>
      <clipPath id="r">
      <rect width="97" height="20" rx="3" fill="#fff"/>
      </clipPath>
      <g clip-path="url(#r)">
      <rect width="61" height="20" fill="#555"/>
      <rect x="61" width="36" height="20" fill="#dfb317"/>
      <rect width="97" height="20" fill="url(#s)"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="11">
      <text aria-hidden="true" x="30.5" y="15" fill="#010101" fill-opacity=".3" textLength="50.2">coverage</text>
      <text x="30.5" y="14" textLength="50.2">coverage</text>
      <text aria-hidden="true" x="79" y="15" fill="#010101" fill-opacity=".3" textLength="25.8">75%</text>
      <text x="79" y="14" textLength="25.8">75%</text>
      </g>
      </svg>

# label must be a single string

    Code
      badge(cov, tempfile(), label = c("a", "b"))
    Condition
      Error:
      ! `label` must be a single string.

---

    Code
      badge(cov, tempfile(), label = NA)
    Condition
      Error:
      ! `label` must be a single string.

