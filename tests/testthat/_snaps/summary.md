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

