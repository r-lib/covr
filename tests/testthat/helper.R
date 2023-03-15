is_r_devel <- function() {
  startsWith(R.version$status, "Under development")
}
