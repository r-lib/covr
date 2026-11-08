# coverage_to_markdown() formats totals, files and differences

    Code
      coverage_to_markdown(part)
    Output
      | File | Coverage |
      | :--- | ---: |
      | Total | 66.67% |
      | f.R | 66.67% |
    Code
      coverage_to_markdown(full, base = part)
    Output
      | File | Coverage | Base | Change |
      | :--- | ---: | ---: | ---: |
      | Total | 100.00% | 66.67% | +33.33% |
      | f.R | 100.00% | 66.67% | +33.33% |

# coverage_to_markdown() escapes file names and handles missing/lower base

    Code
      coverage_to_markdown(full)
    Output
      | File | Coverage |
      | :--- | ---: |
      | Total | 100.00% |
      | a\|b&lt;c&gt;.R | 100.00% |
      | new.R | 100.00% |
    Code
      coverage_to_markdown(full, base = part)
    Output
      | File | Coverage | Base | Change |
      | :--- | ---: | ---: | ---: |
      | Total | 100.00% | 66.67% | +33.33% |
      | a\|b&lt;c&gt;.R | 100.00% | 66.67% | +33.33% |
      | new.R | 100.00% |  |  |
    Code
      coverage_to_markdown(part, base = full)
    Output
      | File | Coverage | Base | Change |
      | :--- | ---: | ---: | ---: |
      | Total | 66.67% | 100.00% | -33.33% |
      | a\|b&lt;c&gt;.R | 66.67% | 100.00% | -33.33% |

