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
#'
#' # add your own non-answers
#' na_blank(c("a", "n/a", "N/A"), also = c("n/a", "N/A"))
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
#' A thin, survey-friendly wrapper around [base::cut()] that returns a factor in
#' band order and uses left-closed, right-open intervals by default
#' so that age bands like 18-21 behave intuitively. Generalises the
#' `case_when(age %in% seq(...))` age-grouping pattern.
#'
#' @param x A numeric vector.
#' @param breaks Numeric vector of cut points. With `n` labels you need `n + 1`
#'   breaks. Use `Inf` for an open-ended top band.
#' @param labels Character vector of group labels, length `length(breaks) - 1`.
#' @param right If `TRUE`, intervals are closed on the right; if `FALSE`
#'   (default) closed on the left. Left-closed matches "18 to 21" style bands.
#' @param quiet If `TRUE`, do not report values that fell outside `breaks`.
#'
#' @return A factor whose levels are `labels` in the order given (values
#'   outside the range or `NA` become `NA`).
#'
#' @details
#' Bands are built with [base::cut()] using `include.lowest = TRUE`, so the very
#' lowest break is included. With `right = FALSE` (the default) a band runs from
#' its lower break up to *but not including* the next -- i.e. `[18, 25)` -- which
#' is what you want for age groups like "18 to 24". Text input is salvaged with
#' [ensure_numeric()], so `"27 years"` bins correctly. The result is a factor
#' whose levels follow `labels`, so tables and charts built from it list the
#' bands low to high ("40-70k" before "100-150k") rather than alphabetically.
#' Wrap it in [as.character()] if you need plain text.
#'
#' A value below the first break or above the last becomes `NA` and drops out of
#' every chart built from the result, so the function says how many did and what
#' their range was. A closed top band such as `35` to `40.5` under a label of
#' "35 to 40+" is the usual cause; `Inf` is what that label means.
#'
#' @family recode
#' @seealso [recode_age()] for a ready-made age-band wrapper, [ensure_numeric()].
#' @examples
#' bin_numeric(c(15, 19, 27, 41),
#'             breaks = c(0, 18, 25, 35, Inf),
#'             labels = c("<18", "18-24", "25-34", "35+"))
#' @export
bin_numeric <- function(x, breaks, labels, right = FALSE, quiet = FALSE) {
  if (length(labels) != length(breaks) - 1L) {
    stop("`labels` must have length `length(breaks) - 1`.", call. = FALSE)
  }
  values <- ensure_numeric(x, quiet = TRUE)
  out <- cut(
    values,
    breaks = breaks,
    labels = labels,
    right = right,
    include.lowest = TRUE
  )
  dropped <- !is.na(values) & is.na(out)
  if (!quiet && any(dropped)) {
    outside <- range(values[dropped])
    message("bin_numeric: ", sum(dropped), " value(s) fell outside the breaks ",
            "and became NA (range ", outside[1], " to ", outside[2],
            "). Widen `breaks`, e.g. with -Inf / Inf at the ends.")
  }
  out
}

#' Recode age into standard survey bands
#'
#' Convenience wrapper over [bin_numeric()] using the standard survey age
#' bands. Also tolerates messy inputs such as "25 years" by
#' extracting the first run of digits.
#'
#' @param x A numeric or character vector of ages.
#' @param breaks,labels Override the default bands if needed; the defaults come
#'   from the `age_breaks` / `age_labels` options (see [ezrsurvey_options()]).
#' @param quiet If `FALSE` (default), report answers that held no number and
#'   answers that fell outside the bands. Set `TRUE` to silence both.
#'
#' @return A factor of age-band labels, levels in band order.
#'
#' @details
#' Ages are first passed through [ensure_numeric()], so messy entries like
#' `"22 years"` or `"age: 31"` are handled, then binned with [bin_numeric()]
#' using left-closed bands. An answer with no number in it at all (`"young"`,
#' `"prefer not to say"`) becomes `NA` and is counted in a message, so a column
#' that was never numeric does not pass for a column of missing ages. The
#' default bands come from the `age_breaks` /
#' `age_labels` options, so you can set your study's standard cohorts once with
#' `ezrsurvey_options(age_breaks = ..., age_labels = ...)` (or a profile) instead
#' of passing them on every call. For *generational* cohorts (Gen Z, Millennial,
#' ...) use [recode_generation()] instead.
#'
#' @family recode
#' @seealso [bin_numeric()], [recode_generation()], [ezrsurvey_options()].
#' @examples
#' recode_age(c("17", "22 years", "31", "47"))
#' @export
recode_age <- function(x,
                       breaks = ezrsurvey_default("age_breaks"),
                       labels = ezrsurvey_default("age_labels"),
                       quiet = FALSE) {
  num <- ensure_numeric(x, quiet = TRUE)
  # bin_numeric() reports ages that fall outside the bands, but an answer that
  # held no number at all is already NA by then and would vanish in silence.
  unparsed <- sum(is.na(num) & !is.na(x) & nzchar(trimws(as.character(x))))
  if (!quiet && unparsed > 0) {
    message("recode_age: ", unparsed, " value(s) held no number and became NA.")
  }
  bin_numeric(num, breaks = breaks, labels = labels, quiet = quiet)
}

#' Recode a worded rating scale to integers
#'
#' Maps the worded answers of an ordinal rating question (e.g. "Very bad" ...
#' "Very good") onto integers `1:length(levels)`. Matching is case-insensitive
#' and tolerant of common synonyms supplied via `synonyms`, in place of a
#' `case_when(str_detect("Very bad") ...)` recoding block.
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
#' The substring passes try the longest wording first, so a scale whose levels
#' nest inside one another ("Likeable" inside "Very likeable", "Good" inside
#' "Very good") resolves to the level the answer actually names. Without that,
#' any answer the exact pass misses, such as one carrying an emoji or a stray
#' character, would quietly land on the shorter level.
#'
#' @family recode
#' @seealso [nps_group()], [ipm_model()], [calc_summary()].
#' @examples
#' recode_likert(c("Very bad", "Ok", "Good", "Very good"))
#'
#' # substring fallback copes with numbered labels
#' recode_likert("4 - Good")
#'
#' # nested wordings resolve to the level the answer names, not the shorter one
#' recode_likert(c("\U0001F642 Very good", "\U0001F610 Good"))
#'
#' # map another tool's wording onto the same scale
#' recode_likert(c("Dissatisfied", "Satisfied"),
#'               synonyms = list(Bad = "Dissatisfied", Good = "Satisfied"),
#'               levels = c("Very bad", "Bad", "Ok", "Good", "Very good"))
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

  # Substring fallback for the canonical wordings (handles "1 - Very good" etc.).
  # Longest level first, or "Very good" would match the "good" nested inside it.
  still_na <- is.na(out)
  if (any(still_na)) {
    longest_first <- order(nchar(lower_levels), decreasing = TRUE)
    for (i in longest_first) {
      hit <- still_na &
        stringr::str_detect(tolower(x_chr), stringr::fixed(lower_levels[i]))
      out[hit] <- i
      still_na <- is.na(out)
    }
  }

  # User-supplied synonyms, gathered first so every target is checked up front.
  if (!is.null(synonyms)) {
    alternatives <- character(0)
    targets <- integer(0)
    for (canon in names(synonyms)) {
      idx <- match(tolower(canon), lower_levels)
      if (is.na(idx)) {
        stop("Synonym target '", canon, "' is not one of `levels`.",
             call. = FALSE)
      }
      alternatives <- c(alternatives, synonyms[[canon]])
      targets <- c(targets, rep(idx, length(synonyms[[canon]])))
    }
    # Longest first, for the same reason as the level fallback above.
    longest_first <- order(nchar(alternatives), decreasing = TRUE)
    for (j in longest_first) {
      hit <- is.na(out) &
        stringr::str_detect(tolower(x_chr),
                            stringr::fixed(tolower(alternatives[j])))
      out[hit] <- targets[j]
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
#'
#' nps_group(c(3, 8, 10), labels = TRUE)
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

# Internal: the delimiters an export is likely to pack answers with, in
# precedence order. A semicolon wins over a comma because an export that uses
# semicolons is usually doing so precisely because the answers contain commas.
multi_delimiters <- c(";", "|", ",")

# Internal: which delimiter a column of packed answers uses, or NULL when no
# cell holds more than one answer.
detect_delimiter <- function(x) {
  x <- x[!is.na(x) & x != ""]
  for (d in multi_delimiters) {
    if (any(stringr::str_detect(x, stringr::fixed(d)))) {
      return(d)
    }
  }
  NULL
}

# Internal: one row per respondent-answer pair from a packed column. Shared by
# split_multi() and calc_percentage_multi().
unpack_answers <- function(values, delim) {
  parts <- if (is.null(delim)) {
    as.list(values)
  } else {
    stringr::str_split(values, stringr::fixed(delim))
  }
  lapply(parts, function(p) {
    p <- stringr::str_squish(p)
    p[!is.na(p) & p != ""]
  })
}

#' Split a packed multi-select column into one column per answer
#'
#' Turns the single cell a spreadsheet export gives a "tick all that apply"
#' question (`"Speed; Drivers; Betting"`) into the one-column-per-option layout
#' the rest of the package expects, so [calc_percentage_multi()], [crosstab()]
#' and the plots all work on it.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()]) is
#'   used.
#' @param column The packed column (unquoted).
#' @param split The delimiter between answers inside a cell. `"auto"` (default)
#'   detects `";"`, `"|"` or `","`, in that order. Pass a string to force one.
#' @param prefix Prefix for the new column names. Defaults to the column's own
#'   name followed by an underscore, e.g. `motivations_`.
#'
#' @return The data frame with one new column per distinct answer, each holding
#'   the answer text for respondents who chose it and `""` for those who did
#'   not, ordered most-chosen first. The packed column is kept.
#'
#' @details
#' Google Forms, Google Sheets and most survey platforms export a multi-select
#' question as one cell per respondent holding every answer they ticked, joined
#' by a delimiter. That shape cannot be counted directly, because a respondent
#' who ticked three options is one row, not three. This function unpacks it into
#' the indicator layout the package's own datasets use.
#'
#' The new columns are named `prefix` plus the answer text verbatim, which keeps
#' the labels readable all the way through to a chart: `calc_percentage_multi()`
#' strips the prefix back off and uses what remains as the option label. Answer
#' text is rarely a syntactic R name, so refer to the new columns with backticks
#' if you need them individually. Surrounding whitespace is trimmed and empty
#' answers are dropped, so `"Speed;  ; Drivers"` yields two options. When no cell
#' contains the delimiter, each cell is treated as a single answer, which is the
#' right answer for a multi-select question everyone happened to answer once.
#'
#' If you only want the percentages, skip this step: [calc_percentage_multi()]
#' detects a packed column and splits it for you.
#'
#' @family recode
#' @seealso [calc_percentage_multi()], [na_blank()].
#' @examples
#' packed <- data.frame(
#'   respondent = 1:4,
#'   motivations = c("Speed; Drivers", "Speed", "", "Betting; Speed")
#' )
#' split_multi(packed, motivations)
#'
#' split_multi(packed, motivations) %>%
#'   calc_percentage_multi("motivations_", id = respondent, sort = "desc")
#' @export
split_multi <- function(data = NULL, column, split = "auto", prefix = NULL) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(column)),
                            missing(column))
  data <- r$data
  col_name <- col_label(r$cols[[1]], data)
  if (is.null(prefix)) prefix <- paste0(col_name, "_")

  values <- na_blank(data[[col_name]])
  delim <- if (identical(split, "auto")) detect_delimiter(values) else split
  chosen <- unpack_answers(values, delim)

  ranked <- sort(table(unlist(chosen)), decreasing = TRUE)
  answers <- names(ranked)
  if (length(answers) == 0L) {
    stop("Column '", col_name, "' holds no answers to split.", call. = FALSE)
  }

  for (answer in answers) {
    picked <- vapply(chosen, function(p) answer %in% p, logical(1))
    data[[paste0(prefix, answer)]] <- ifelse(picked, answer, "")
  }
  tibble::as_tibble(data)
}
