exclude_ops <- list(
  exclude_pattern = "#TeSt_NoLiNt",
  exclude_start = "#TeSt_NoLiNt_StArT",
  exclude_end = "#TeSt_NoLiNt_EnD"
)

expect_equal_vals <- function(x, y) {
  testthat::expect_equal(unname(x), unname(y))
}
