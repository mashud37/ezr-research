#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data
#' @importFrom tibble tibble
## usethis namespace: end
NULL

# Quiet R CMD check for the teaching dataset and the bare NSE column symbols the
# generators pass to ezr verbs.
utils::globalVariables(c(".", "theme_park", "visitor_type", "region", "nps",
                         "comment"))
