#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data := enquo enquos quo_is_null as_name sym syms
#' @importFrom dplyr %>%
## usethis namespace: end
NULL

# Quiet R CMD check notes about unquoted column names used in NSE pipelines.
utils::globalVariables(c(
  ".", "n", "value", "variable", "term", "estimate", "importance", "rank",
  "method", "cluster", "size", ".cluster", "component", "loading", "where",
  "nps_drivers", "ecommerce", "reviews", "consensus", "feature", "target"
))
