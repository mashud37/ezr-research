#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data := enquo enquos quo_is_null as_name sym syms
#' @importFrom dplyr %>%
## usethis namespace: end
NULL

# The packages ezrsurvey wraps are attached for the user (Depends), and the code
# reaches them as ggplot2::, tibble:: and so on. Naming one symbol from each
# also imports them, which is what makes the namespace work when it is loaded
# without being attached.
#' @importFrom ggplot2 aes
#' @importFrom tibble tibble
#' @importFrom tidyr pivot_longer
#' @importFrom readr write_csv
#' @importFrom stringr str_wrap
#' @importFrom purrr map
NULL

# Quiet R CMD check notes about unquoted column names used in NSE pipelines and
# about variables bound inside data-masked expressions.
utils::globalVariables(c(
  ".", "n", "pct", "prop", "value", "variable", "kvar", "feature",
  "importance", "performance", "estimate", "se", "rse_val", "moe",
  "label", "avg", "weighted", "respondent_id", "where", "country_region",
  "comment", "source", "info", "length", "nps_value", "group",
  "currency_rates", "currency", "per_usd", "difference", "answer"
))
