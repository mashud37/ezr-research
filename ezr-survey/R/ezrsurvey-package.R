#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data := enquo enquos quo_is_null as_name sym syms
#' @importFrom dplyr %>%
## usethis namespace: end
NULL

# ezrsurvey wraps the tidyverse, so attaching it attaches the tidyverse too
# (Depends). Importing one symbol keeps R CMD check from reporting a Depends
# package that is never imported from.
#' @importFrom tidyverse tidyverse_packages
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
