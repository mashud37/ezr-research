#' Convert blank and boilerplate non-answers to `NA`
#'
#' Data exports are littered with empty strings and standard "non-answer"
#' options such as "Prefer not to answer". This helper turns those into real
#' `NA` values so they drop out of models and summaries, replacing the
#' repetitive `filter(x != "", x != "Prefer not to answer")` idiom.
#'
#' @param x A character (or factor) vector.
#' @param also Additional exact strings to treat as missing. Defaults to the
#'   `na_answers` option (`"Prefer not to answer"`; see [ezrmodel_options()]).
#'   Set to `character(0)` to only blank out `""`.
#' @param trim Whether to trim surrounding whitespace before comparing.
#'   Defaults to `TRUE`.
#'
#' @return A character vector the same length as `x`, with blanks and
#'   non-answers replaced by `NA`.
#'
#' @details
#' The input is coerced to character (so factors are handled), optionally
#' whitespace-trimmed, and any value equal to `""` or to one of `also` becomes
#' `NA`. The default `also` reads the `na_answers` option, so you can change what
#' counts as a non-answer package-wide with
#' `ezrmodel_options(na_answers = ...)`. The modelling helpers call `na_blank()`
#' for you when cleaning categorical columns.
#'
#' @family prep
#' @seealso [ensure_numeric()], [ezrmodel_options()].
#' @examples
#' na_blank(c("Yes", "", "Prefer not to answer", "No"))
#' #> [1] "Yes" NA    NA    "No"
#'
#' na_blank(c("a", "n/a", "N/A"), also = c("n/a", "N/A"))
#' #> [1] "a" NA  NA
#' @export
na_blank <- function(x, also = ezrmodel_default("na_answers"), trim = TRUE) {
  x <- as.character(x)
  if (trim) {
    x <- stringr::str_trim(x)
  }
  drop <- c("", also)
  x[x %in% drop] <- NA_character_
  x
}
