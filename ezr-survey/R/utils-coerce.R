#' Coerce text to numeric, salvaging embedded numbers
#'
#' A defensive helper for the common survey-export headache where a column that
#' should be numeric arrives as text -- `"25 years"`, `"8 - very likely"`,
#' `"3.5/5"`. It returns `x` unchanged if it is already numeric; otherwise it
#' pulls the first number out of each value (via a digit pattern) and coerces to
#' numeric, leaving genuinely unparseable entries as `NA`. The ezrsurvey
#' functions that need numbers (e.g. [calc_nps()], [calc_summary()]) call this
#' for you, so they "just work" on lightly messy data.
#'
#' @param x A vector. Numeric input is returned as-is.
#' @param name Optional column/argument name, used only to make the message
#'   clearer.
#' @param quiet If `FALSE` (default), emit a one-line message when coercion
#'   happens (and note any values that could not be parsed). Set `TRUE` to
#'   silence it.
#'
#' @return A numeric vector the same length as `x`.
#'
#' @details
#' The first numeric token in each value is extracted with the pattern
#' `-?[0-9]*\.?[0-9]+`, which captures negatives and decimals but takes only the
#' *first* number it finds -- so `"8 - very likely"` becomes `8`, not `-8`. A
#' value that is genuinely numeric already is returned untouched (no copy, no
#' message). When `quiet = FALSE` a single informative message reports that
#' coercion happened and how many values could not be parsed; the internal
#' callers ([calc_nps()], [calc_summary()], [ipm_model()], [bin_numeric()], ...)
#' pass `quiet = TRUE` so they don't spam your console. Truly blank entries
#' (`""`/`NA`) are not counted as parse failures.
#'
#' @family recode
#' @seealso [recode_age()], [recode_likert()], [na_blank()].
#' @examples
#' ensure_numeric(c("25 years", "31", "forty"), quiet = TRUE)
#' #> [1] 25 31 NA
#'
#' ensure_numeric(c("8 - very likely", "10", "3.5/5"), quiet = TRUE)
#' #> [1]  8.0 10.0  3.5
#'
#' ensure_numeric(c(1, 2, 3))    # already numeric, returned as-is
#' #> [1] 1 2 3
#' @export
ensure_numeric <- function(x, name = NULL, quiet = FALSE) {
  if (is.numeric(x)) {
    return(x)
  }
  raw <- as.character(x)
  token <- stringr::str_extract(raw, "-?[0-9]*\\.?[0-9]+")
  num <- suppressWarnings(as.numeric(token))

  if (!quiet) {
    label <- if (is.null(name)) "input" else paste0("'", name, "'")
    lost <- sum(is.na(num) & !is.na(raw) & nzchar(trimws(raw)))
    msg <- sprintf("Auto-converted %s to numeric.", label)
    if (lost > 0) {
      msg <- paste0(msg, sprintf(
        " %d value(s) could not be parsed and became NA.", lost))
    }
    rlang::inform(msg)
  }
  num
}
