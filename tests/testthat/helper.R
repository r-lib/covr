is_r_devel <- function() {
  startsWith(R.version$status, "Under development")
}

is_win_r41 <- function() {
  x <- getRversion()
  is_windows() && x$major == 4 && x$minor == 1
}
