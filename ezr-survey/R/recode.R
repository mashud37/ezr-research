#' Convert blank and boilerplate non-answers to `NA`
#'
#' Survey exports are littered with empty strings and standard "non-answer"
#' options such as "Prefer not to answer". This helper turns those into real
#' `NA` values so they drop out of counts and summaries, replacing the
#' repetitive `filter(x != "", x != "Prefer not to answer")` idiom.
#'
#' @param x A character (or factor) vector.
#' @param also Additional exact strings to treat as missing. Defaults to the
#'   `na_answers` option (`"Prefer not to answer"`; see [ezrsurvey_options()]).
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
#' `ezrsurvey_options(na_answers = ...)`. Most of the `calc_*` helpers call
#' `na_blank()` internally when `na_rm = TRUE`, so you usually get this clean-up
#' for free; call it directly when you want to blank a column in a pipeline.
#'
#' @family recode
#' @seealso [ensure_numeric()], [ezrsurvey_options()].
#' @examples
#' na_blank(c("Yes", "", "Prefer not to answer", "No"))
#' #> [1] "Yes" NA    NA    "No"
#'
#' # add your own non-answers
#' na_blank(c("a", "n/a", "N/A"), also = c("n/a", "N/A"))
#' #> [1] "a" NA  NA
#' @export
na_blank <- function(x, also = ezrsurvey_default("na_answers"), trim = TRUE) {
  x <- as.character(x)
  if (trim) {
    x <- stringr::str_trim(x)
  }
  drop <- c("", also)
  x[x %in% drop] <- NA_character_
  x
}

#' Drop unwanted answer categories from a question
#'
#' Removes specific answer values -- typically catch-all or uninformative options
#' such as "Other", "Don't know" or "Not applicable" -- by turning them into
#' `NA`, so they fall out of counts, percentages and charts and the remaining
#' percentages re-base on the answers you keep. The companion to [na_blank()]
#' (which targets blanks and standard non-answers): use `drop_items()` for the
#' substantive categories you simply do not want to show.
#'
#' @param x A character (or factor) vector.
#' @param items Character vector of exact answer values to drop. Matching is
#'   case-insensitive.
#' @param trim Whether to trim surrounding whitespace before comparing. Defaults
#'   to `TRUE`.
#'
#' @return A character vector the same length as `x`, with any value matching
#'   `items` replaced by `NA`.
#'
#' @details
#' `x` is coerced to character (so factors are handled) and, by default,
#' whitespace-trimmed; any value equal (ignoring case) to one of `items` becomes
#' `NA`. The summary helpers ([calc_percentage()], [calc_percentage_multi()],
#' [calc_percentage_batch()]) and [crosstab()] take a `drop =` argument that
#' applies this for you *before* counting, so the kept answers re-base to ~100%;
#' set a session-wide default with `ezrsurvey_options(drop_answers = ...)`.
#'
#' @family recode
#' @seealso [na_blank()], [calc_percentage()].
#' @examples
#' drop_items(c("Yes", "No", "Other", "Don't know"),
#'            items = c("Other", "Don't know"))
#' #> [1] "Yes" "No"  NA    NA
#' @export
drop_items <- function(x, items, trim = TRUE) {
  x <- as.character(x)
  if (is.null(items) || length(items) == 0L) {
    return(x)
  }
  cmp <- if (trim) stringr::str_trim(x) else x
  x[tolower(cmp) %in% tolower(items)] <- NA_character_
  x
}

#' Bin a numeric vector into labelled groups
#'
#' A thin, survey-friendly wrapper around [base::cut()] that returns a character
#' vector (not a factor) and uses left-closed, right-open intervals by default
#' so that age bands like 18-21 behave intuitively. Generalises the
#' `case_when(age %in% seq(...))` age-grouping pattern from the original
#' reports.
#'
#' @param x A numeric vector.
#' @param breaks Numeric vector of cut points. With `n` labels you need `n + 1`
#'   breaks. Use `Inf` for an open-ended top band.
#' @param labels Character vector of group labels, length `length(breaks) - 1`.
#' @param right If `TRUE`, intervals are closed on the right; if `FALSE`
#'   (default) closed on the left. Left-closed matches "18 to 21" style bands.
#'
#' @return A character vector of group labels (values outside the range or `NA`
#'   become `NA`).
#'
#' @details
#' Bands are built with [base::cut()] using `include.lowest = TRUE`, so the very
#' lowest break is included. With `right = FALSE` (the default) a band runs from
#' its lower break up to *but not including* the next -- i.e. `[18, 25)` -- which
#' is what you want for age groups like "18 to 24". Text input is salvaged with
#' [ensure_numeric()], so `"27 years"` bins correctly. The result is a plain
#' character vector (not a factor); apply an order later with [register_order()]
#' or pass `levels =` to [calc_percentage()] if you need a specific display
#' order.
#'
#' @family recode
#' @seealso [recode_age()] for a ready-made age-band wrapper, [ensure_numeric()].
#' @examples
#' bin_numeric(c(15, 19, 27, 41),
#'             breaks = c(0, 18, 25, 35, Inf),
#'             labels = c("<18", "18-24", "25-34", "35+"))
#' #> [1] "<18"   "18-24" "25-34" "35+"
#' @export
bin_numeric <- function(x, breaks, labels, right = FALSE) {
  if (length(labels) != length(breaks) - 1L) {
    stop("`labels` must have length `length(breaks) - 1`.", call. = FALSE)
  }
  out <- cut(
    ensure_numeric(x, quiet = TRUE),
    breaks = breaks,
    labels = labels,
    right = right,
    include.lowest = TRUE
  )
  as.character(out)
}

#' Recode age into standard survey bands
#'
#' Convenience wrapper over [bin_numeric()] using the default age bands from the
#' original viewer surveys. Also tolerates messy inputs such as "25 years" by
#' extracting the first run of digits.
#'
#' @param x A numeric or character vector of ages.
#' @param breaks,labels Override the default bands if needed; the defaults come
#'   from the `age_breaks` / `age_labels` options (see [ezrsurvey_options()]).
#'
#' @return A character vector of age-band labels.
#'
#' @details
#' Ages are first passed through [ensure_numeric()], so messy entries like
#' `"22 years"` or `"age: 31"` are handled, then binned with [bin_numeric()]
#' using left-closed bands. The default bands come from the `age_breaks` /
#' `age_labels` options, so you can set your study's standard cohorts once with
#' `ezrsurvey_options(age_breaks = ..., age_labels = ...)` (or a profile) instead
#' of passing them on every call. For *generational* cohorts (Gen Z, Millennial,
#' ...) use [recode_generation()] instead.
#'
#' @family recode
#' @seealso [bin_numeric()], [recode_generation()], [ezrsurvey_options()].
#' @examples
#' recode_age(c("17", "22 years", "31", "47"))
#' #> [1] "17 or younger" "22 to 25"      "30 to 34"      "35+"
#' @export
recode_age <- function(x,
                       breaks = ezrsurvey_default("age_breaks"),
                       labels = ezrsurvey_default("age_labels")) {
  num <- ensure_numeric(x, quiet = TRUE)
  bin_numeric(num, breaks = breaks, labels = labels)
}

#' Recode a worded rating scale to integers
#'
#' Maps the worded answers of an ordinal rating question (e.g. "Very bad" ...
#' "Very good") onto integers `1:length(levels)`. Matching is case-insensitive
#' and tolerant of common synonyms supplied via `synonyms`, reproducing the
#' `case_when(str_detect("Very bad") ...)` recoding blocks from the reports.
#'
#' @param x A character (or factor) vector of worded answers.
#' @param levels Character vector of the scale's answer wordings in ascending
#'   order. The first element maps to `1`, the last to `length(levels)`.
#'   Defaults to a 5-point bad-to-good scale.
#' @param synonyms Optional named list mapping a canonical level (one of
#'   `levels`) to a character vector of alternative spellings that should map to
#'   the same integer. Matching is by case-insensitive substring.
#'
#' @return An integer vector the same length as `x`; unmatched values become
#'   `NA`.
#'
#' @details
#' Matching happens in three passes, in order: (1) an exact, case-insensitive,
#' trimmed match against `levels`; (2) a substring fallback, so prefixed exports
#' like `"4 - Good"` still resolve; (3) any `synonyms` you supply. This makes the
#' function robust to the small wording differences between survey tools (e.g.
#' "Dissatisfied" vs "Bad"). Turning ratings into integers is the first step of
#' [ipm_model()] and lets you average a scale with [calc_summary()].
#'
#' @family recode
#' @seealso [nps_group()], [ipm_model()], [calc_summary()].
#' @examples
#' recode_likert(c("Very bad", "Ok", "Good", "Very good"))
#' #> [1] 1 3 4 5
#'
#' # substring fallback copes with numbered labels
#' recode_likert("4 - Good")
#' #> [1] 4
#'
#' # map another tool's wording onto the same scale
#' recode_likert(c("Dissatisfied", "Satisfied"),
#'               synonyms = list(Bad = "Dissatisfied", Good = "Satisfied"),
#'               levels = c("Very bad", "Bad", "Ok", "Good", "Very good"))
#' #> [1] 2 4
#' @export
recode_likert <- function(x,
                          levels = c("Very bad", "Bad", "Ok", "Good", "Very good"),
                          synonyms = NULL) {
  x_chr <- as.character(x)
  out <- rep(NA_integer_, length(x_chr))

  # Exact (case-insensitive) matches first.
  lower_levels <- tolower(levels)
  match_idx <- match(tolower(stringr::str_trim(x_chr)), lower_levels)
  out <- match_idx

  # Substring fallback for the canonical wordings (handles "1 - Very good" etc.)
  still_na <- is.na(out)
  if (any(still_na)) {
    for (i in seq_along(levels)) {
      hit <- still_na &
        stringr::str_detect(tolower(x_chr), stringr::fixed(lower_levels[i]))
      out[hit] <- i
      still_na <- is.na(out)
    }
  }

  # User-supplied synonyms.
  if (!is.null(synonyms)) {
    for (canon in names(synonyms)) {
      idx <- match(tolower(canon), lower_levels)
      if (is.na(idx)) {
        stop("Synonym target '", canon, "' is not one of `levels`.",
             call. = FALSE)
      }
      for (alt in synonyms[[canon]]) {
        hit <- is.na(out) &
          stringr::str_detect(tolower(x_chr), stringr::fixed(tolower(alt)))
        out[hit] <- idx
      }
    }
  }

  as.integer(out)
}

#' Classify Net Promoter Score answers into groups
#'
#' Collapses an 0-10 "how likely to recommend" question into the three standard
#' NPS groups: detractors (0-6), passives (7-8) and promoters (9-10).
#'
#' @param x A numeric vector of 0-10 ratings (character input is coerced).
#' @param labels If `FALSE` (default) returns the signed integer coding
#'   `-1 / 0 / 1` used by [calc_nps()]. If `TRUE` returns the labels
#'   `"Detractor" / "Passive" / "Promoter"`.
#'
#' @return Either an integer vector (`-1/0/1`) or a character vector, the same
#'   length as `x`. Out-of-range or missing values become `NA`.
#'
#' @details
#' The signed `-1/0/1` coding is deliberate: the mean of it, times 100, is
#' exactly the Net Promoter Score (% promoters minus % detractors), which is how
#' [calc_nps()] computes the headline number. Inputs are run through
#' [ensure_numeric()] first, so worded answers like `"9 - very likely"` are
#' classified correctly. Values outside 0--10 (and `NA`) return `NA`.
#'
#' @family recode
#' @seealso [calc_nps()], [plot_nps()].
#' @examples
#' nps_group(c(0, 6, 7, 8, 9, 10))
#' #> [1] -1 -1  0  0  1  1
#'
#' nps_group(c(3, 8, 10), labels = TRUE)
#' #> [1] "Detractor" "Passive"   "Promoter"
#' @export
nps_group <- function(x, labels = FALSE) {
  v <- ensure_numeric(x, quiet = TRUE)
  g <- dplyr::case_when(
    v >= 0 & v <= 6  ~ -1L,
    v >= 7 & v <= 8  ~  0L,
    v >= 9 & v <= 10 ~  1L,
    TRUE             ~ NA_integer_
  )
  if (labels) {
    dplyr::case_when(
      g == -1L ~ "Detractor",
      g ==  0L ~ "Passive",
      g ==  1L ~ "Promoter",
      TRUE     ~ NA_character_
    )
  } else {
    g
  }
}
