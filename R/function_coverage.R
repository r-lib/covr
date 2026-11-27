#' Calculate test coverage for a specific function.
#'
#' @param fun name of the function.
#' @param code expressions to run.
#' @param env environment the function is defined in.
#' @param enc the enclosing environment which to run the expressions.
#' @inheritSection file_coverage Parallel code
#' @return A [coverage] object.
#' @examples
#' add <- function(x, y) { x + y }
#' function_coverage(fun = add, code = NULL) # 0% coverage
#' function_coverage(fun = add, code = add(1, 2) == 3) # 100% coverage
#' @export
function_coverage <- function(
  fun,
  code = NULL,
  env = NULL,
  enc = parent.frame()
) {
  if (is.function(fun)) {
    env <- environment(fun)

    # get name of function, stripping preceding blah:: if needed
    fun <- rex::re_substitutes(
      deparse(substitute(fun)),
      rex::regex(".*:::?"),
      ""
    )
  }

  local_anonymous_scope()
  clear_counters(anonymous_scope)

  replacement <- if (!is.null(env)) {
    replacement(fun, env)
  } else {
    replacement(fun)
  }

  trace_replacement(replacement, anonymous_scope)

  collect_coverage(eval(code, enc))
}
