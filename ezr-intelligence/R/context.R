# Internal: the worst-case (p = 0.5) margin of error a simple random sample of
# `n` supports, in percentage points, as a sentence the model can quote.
margin_of_error_note <- function(n) {
  if (is.null(n) || is.na(n) || n < 2) {
    return(NULL)
  }
  z <- ezrintelligence_default("confidence_z")
  moe <- 100 * z * sqrt(0.25 / n)
  paste0("a percentage from the full sample carries a margin of error of ",
         "about +/- ", format(round(moe, 1), nsmall = 1),
         " percentage points, so differences smaller than that are not ",
         "reliable")
}

#' Describe the study behind a table
#'
#' Bundles the facts a good analyst would want next to any table -- sample
#' size, question wording, base, precision -- so [ai_summarise()] and
#' [ai_slide_text()] can pass them to the model alongside the figures. Given
#' the raw respondent-level `data`, the sample size and a margin-of-error note
#' are derived for you.
#'
#' @param data Optional raw data (one row per respondent). Used only to derive
#'   `n` and, from it, the default `precision` note; the rows themselves are
#'   never sent to a provider.
#' @param n Sample size. Derived from `data` when omitted.
#' @param question The verbatim question wording behind the table(s).
#' @param base Who was asked, e.g. `"All respondents"` or
#'   `"Detractors only (n = 142)"`.
#' @param precision Character vector of precision notes. Derived from the
#'   sample size when omitted. Pass your own (for instance the bullets from a
#'   proper design-effect calculation) to override it.
#' @param fieldwork Fieldwork description, e.g. `"12-19 May 2026, online
#'   panel"`.
#' @param notes Any further context worth giving the model.
#'
#' @return An `ezrintelligence_context` list.
#'
#' @details
#' Context is what turns a generic summary into an analyst's summary: with a
#' sample size and margin of error present, the built-in templates flag
#' differences within the margin of error instead of narrating noise, and cite
#' the base alongside findings. Reuse one context object across every
#' [ai_summarise()] call for the same study.
#'
#' The derived precision note is the textbook worst case for a simple random
#' sample: the margin of error at `p = 0.5` and the confidence level set by the
#' `confidence_z` option. It ignores weighting, clustering and finite
#' populations, so pass `precision` yourself when you have a real design-effect
#' figure.
#'
#' @family ai
#' @seealso [ai_summarise()], [ai_report_sections()].
#' @examples
#' ctx <- ai_context(
#'   n = 1000,
#'   question = "How likely are you to recommend us?",
#'   base = "All respondents",
#'   fieldwork = "12-19 May 2026, online panel"
#' )
#' ctx
#' #> Study context for AI summaries
#' #> Study context:
#' #> - Sample size: n = 1000
#' #> - Question asked: How likely are you to recommend us?
#' #> - Base: All respondents
#' #> - Fieldwork: 12-19 May 2026, online panel
#' #> - Precision: a percentage from the full sample carries a margin of error
#' #>   of about +/- 3.1 percentage points, ...
#' @export
ai_context <- function(data = NULL, n = NULL, question = NULL, base = NULL,
                       precision = NULL, fieldwork = NULL, notes = NULL) {
  if (!is.null(data)) {
    n <- n %||% nrow(data)
  }
  if (is.null(precision) && !is.null(n)) {
    precision <- margin_of_error_note(n)
  }
  structure(
    list(n = n, question = question, base = base, precision = precision,
         fieldwork = fieldwork, notes = notes),
    class = "ezrintelligence_context"
  )
}

#' @export
print.ezrintelligence_context <- function(x, ...) {
  cat("Study context for AI summaries\n")
  cat(format_context_for_llm(x), "\n", sep = "")
  invisible(x)
}

# Internal: render an ai_context() (or a plain string) as the prompt's
# "Study context" block.
format_context_for_llm <- function(context) {
  if (is.character(context)) {
    return(paste0("Study context:\n", paste(context, collapse = "\n")))
  }
  lines <- c(
    if (!is.null(context$n)) paste0("- Sample size: n = ", context$n),
    if (!is.null(context$question)) {
      paste0("- Question asked: ", context$question)
    },
    if (!is.null(context$base)) paste0("- Base: ", context$base),
    if (!is.null(context$fieldwork)) {
      paste0("- Fieldwork: ", context$fieldwork)
    },
    if (!is.null(context$precision)) {
      paste0("- Precision: ", context$precision)
    },
    if (!is.null(context$notes)) paste0("- Notes: ", context$notes)
  )
  if (!length(lines)) return(NULL)
  paste0("Study context:\n", paste(lines, collapse = "\n"))
}
