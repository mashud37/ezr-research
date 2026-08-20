#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dplyr %>%
## usethis namespace: end
NULL

# The first argument unless it is NULL, in which case the second. Used
# throughout to let an argument fall back to an option or a derived value.
`%||%` <- function(x, y) if (is.null(x)) y else x
