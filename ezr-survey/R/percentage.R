# Internal: tidy a multi-select column name into a readable label.
# Survey exporters mangle "Option A / B" into "Option.A...B"; undo that.
clean_label <- function(x) {
  x %>%
    stringr::str_replace_all("\\.{3}", " / ") %>%
    stringr::str_replace_all("\\.", " ") %>%
    stringr::str_squish()
}

# Internal: remove rows whose `col` value is in the `drop` set (falling back to
# the `drop_answers` option), leaving pre-existing NAs and kept answers intact so
# percentages re-base on what remains. Shared by the percentage helpers.
drop_rows <- function(df, col, drop) {
  if (is.null(drop)) drop <- ezrsurvey_default("drop_answers")
  if (is.null(drop) || length(drop) == 0L) {
    return(df)
  }
  dropped <- is.na(drop_items(df[[col]], drop)) & !is.na(df[[col]])
  df[!dropped, , drop = FALSE]
}

# Internal: order the levels of `key` by `pct` (or by `key` itself) and reorder
# rows to match. Shared by the percentage helpers and the plot wrappers so a
# chart inherits whatever order the table was built with.
order_factor <- function(df, key, sort = c("none", "desc", "asc"),
                         levels = NULL) {
  sort <- match.arg(sort)
  if (!is.null(levels)) {
    # An explicit / registered order is intentional and ordinal: mark it ordered
    # so downstream helpers (e.g. plot_bars) leave it alone instead of resorting.
    df[[key]] <- factor(df[[key]], levels = levels, ordered = TRUE)
    return(df)
  }
  if (sort == "none") {
    return(df)
  }
  ord_col <- if ("pct" %in% names(df)) "pct" else key
  o <- order(df[[ord_col]], decreasing = (sort == "desc"))
  df <- df[o, , drop = FALSE]
  df[[key]] <- factor(df[[key]], levels = unique(as.character(df[[key]])))
  df
}

#' Count a categorical question as percentages
#'
#' The headline helper: replaces the ubiquitous
#' `count(x) %>% mutate(pct = round(n / sum(n) * 100)) %>% select(-n)` dance with a
#' single call. Returns both the raw counts and the percentages, optionally
#' grouped by one or more variables and optionally pivoted to a wide
#' cross-tabulation.
#'
#' @param data A data frame. If omitted, the session default set with
#'   [use_dataset()] is used.
#' @param column The categorical column to tabulate (unquoted).
#' @param by Optional grouping column(s). Percentages are computed *within* each
#'   group so they sum to ~100 per group. Pass one bare name (`by = year`) or
#'   several with `c()` (`by = c(year, game)`).
#' @param sort Level ordering of `column`: `"none"` (default, data order),
#'   `"desc"` (largest percentage first) or `"asc"`.
#' @param levels Optional character vector giving an explicit level order for
#'   `column` (the "custom" ordering mode). Overrides `sort`. If omitted and
#'   `sort = "none"`, a registered order for this variable is applied
#'   automatically (see [register_order()]).
#' @param digits Decimal places for the percentage. Defaults to `0`.
#' @param wide If `TRUE`, pivot to one row per `by` group and one column per
#'   answer (dropping `n`), matching the wide summary tables in the original
#'   workflow. Defaults to `FALSE` (tidy long form).
#' @param na_rm If `TRUE` (default), blanks and "Prefer not to answer" responses
#'   (see [na_blank()]) are dropped before counting.
#' @param drop Optional character vector of answer values to remove before
#'   counting (e.g. `c("Other", "Don't know")`), so the kept answers re-base to
#'   ~100%. Matching is case-insensitive (see [drop_items()]). Defaults to the
#'   `drop_answers` option (`NULL` = drop nothing; see [ezrsurvey_options()]).
#' @param weights Survey weighting for this call: `NULL` (default) uses the
#'   session scheme from [set_weights()] if one is set; `FALSE` forces unweighted;
#'   or pass an ad-hoc scheme (any form [set_weights()] accepts) to weight just
#'   this call. When weighting is active a `wpct` column (weighted percentage) is
#'   added beside `n` and `pct`.
#'
#' @return A [tibble][tibble::tibble] with `column`, `n` and `pct` (and `wpct`
#'   when weighting is active) in long form, or one row per group with an answer
#'   column each (wide form).
#'
#' @details
#' Percentages are computed *within* each group, so they sum to about 100 per
#' group (subject to rounding). The level order of `column` is decided in this
#' order of precedence: an explicit `levels` argument; then a non-`"none"`
#' `sort`; then a registered order for the variable (see [register_order()]);
#' otherwise data order. When `by` is omitted, the `default_by` option is used if
#' set (see [ezrsurvey_options()]), so you can apply a standard breakdown without
#' repeating it. `wide = TRUE` pivots to one row per group with a column per
#' answer -- the shape you want for a slide table or an Excel tab.
#'
#' @family summaries
#' @seealso [calc_percentage_multi()] for check-all-that-apply questions,
#'   [calc_percentage_batch()] for many questions at once, [calc_summary()] for
#'   numeric variables, [register_order()] for reusable level orders.
#'
#' @examples
#' calc_percentage(podracing_survey, demo_gender)
#' #> # A tibble: 3 x 3
#' #>   demo_gender     n   pct
#' #>   <chr>       <int> <dbl>
#' #> 1 Female        399    42
#' #> 2 Male          525    55
#' #> 3 Non-binary     27     3
#'
#' # largest first
#' calc_percentage(podracing_survey, demo_gender, sort = "desc")
#'
#' # grouped and pivoted to a wide cross-tab
#' calc_percentage(podracing_survey, satis_return, by = region, wide = TRUE)
#' @export
calc_percentage <- function(data = NULL, column, by = NULL,
                            sort = c("none", "desc", "asc"),
                            levels = NULL, digits = 0,
                            wide = FALSE, na_rm = TRUE, drop = NULL,
                            weights = NULL) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(column)),
                            missing(column))
  data <- r$data
  sort <- match.arg(sort)
  col_name <- col_label(r$cols[[1]])
  col_sym <- rlang::sym(col_name)
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  w <- resolve_weights(data, weights)
  weighted <- !is.null(w)

  d <- data
  if (weighted) d[[".w"]] <- w
  d <- drop_rows(d, col_name, drop)
  if (na_rm) {
    d[[col_name]] <- na_blank(d[[col_name]])
    d <- dplyr::filter(d, !is.na(.data[[col_name]]))
  }

  grouped <- d
  if (has_by) {
    grouped <- dplyr::group_by(d, dplyr::pick({{ by }}))
  } else {
    # Fall back to the default grouping option, if set (see easystat_options()).
    def <- intersect(as.character(ezrsurvey_default("default_by")), names(d))
    if (length(def) > 0) {
      grouped <- dplyr::group_by(d, dplyr::across(dplyr::all_of(def)))
    }
  }

  if (weighted) {
    out <- grouped %>%
      dplyr::group_by(!!col_sym, .add = TRUE) %>%
      dplyr::summarise(n = dplyr::n(), .wsum = sum(.data$.w),
                       .groups = "drop_last") %>%
      dplyr::mutate(pct = round(.data$n / sum(.data$n) * 100, digits),
                    wpct = round(.data$.wsum / sum(.data$.wsum) * 100, digits)) %>%
      dplyr::ungroup() %>%
      dplyr::select(-".wsum")
  } else {
    out <- grouped %>%
      dplyr::count(!!col_sym, name = "n") %>%
      dplyr::mutate(pct = round(.data$n / sum(.data$n) * 100, digits)) %>%
      dplyr::ungroup()
  }

  # If the caller didn't request an ordering, apply a registered order for this
  # variable (see register_order()), when one exists.
  if (is.null(levels) && sort == "none") {
    levels <- order_for(col_name)
  }
  out <- order_factor(out, col_name, sort = sort, levels = levels)

  if (wide) {
    val_col <- if (weighted) "wpct" else "pct"
    drop_cols <- if (weighted) c("n", "pct") else "n"
    out <- out %>%
      dplyr::select(-dplyr::all_of(drop_cols)) %>%
      tidyr::pivot_wider(names_from = !!col_sym,
                         values_from = dplyr::all_of(val_col))
  }

  tibble::as_tibble(out)
}

#' Tabulate a check-all-that-apply (multi-select) question as percentages
#'
#' Multi-select questions arrive as a block of columns sharing a prefix, each
#' holding the chosen option (or blank). This computes, per option, the share of
#' respondents who selected it -- so the percentages can (and usually do) sum to
#' more than 100. The denominator is the number of distinct respondents who
#' selected at least one option, reproducing the `freq_multiple()` helper from
#' the original reports.
#'
#' @param data A data frame.
#' @param prefix Common column-name prefix identifying the option block, e.g.
#'   `"motivations_"`.
#' @param id Optional respondent identifier column (unquoted) used as the
#'   distinct-respondent denominator. If omitted, each row is treated as one
#'   respondent.
#' @param by Optional grouping column(s); percentages are computed within group.
#' @param sort,digits As in [calc_percentage()]. Sorting acts on the `option`
#'   labels.
#' @param drop Optional character vector of option labels to remove before
#'   counting (matched against the cleaned labels, case-insensitive). Defaults to
#'   the `drop_answers` option. See [drop_items()].
#' @param clean_names If `TRUE` (default), tidy the option labels by stripping
#'   `prefix` and un-mangling exporter artefacts (`"A...B"` -> `"A / B"`).
#'
#' @return A [tibble][tibble::tibble] with `option`, `n` (respondents choosing
#'   it) and `pct`.
#'
#' @details
#' The crucial difference from [calc_percentage()] is the denominator: it is the
#' number of distinct respondents who picked *any* option in the block, not the
#' number of ticks. So if 700 of 1,000 respondents selected at least one
#' motivation, each option's percentage is "out of 700", and the percentages can
#' (and usually do) sum to more than 100. Supply `id` to count distinct
#' respondents exactly; without it, each row counts as one respondent. With
#' `clean_names = TRUE` the option labels are stripped of `prefix` and exporter
#' artefacts like `"A...B"` are turned back into `"A / B"`.
#'
#' @family summaries
#' @seealso [calc_percentage()], [plot_bars()].
#'
#' @examples
#' calc_percentage_multi(podracing_survey, "motivations_",
#'                       id = respondent_id, sort = "desc")
#' #> # A tibble: 5 x 3
#' #>   option        n   pct
#' #>   <fct>     <int> <dbl>
#' #> 1 speed       772    79
#' #> 2 drivers     533    54
#' #> 3 social      437    45
#' #> 4 tradition   349    36
#' #> 5 betting     295    30
#' @export
calc_percentage_multi <- function(data = NULL, prefix, id = NULL, by = NULL,
                                  sort = c("none", "desc", "asc"),
                                  digits = 0, drop = NULL, clean_names = TRUE) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(prefix)),
                            missing(prefix))
  data <- r$data
  prefix <- rlang::eval_tidy(r$cols[[1]])
  sort <- match.arg(sort)
  id_q <- rlang::enquo(id)
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  opt_cols <- names(dplyr::select(data, dplyr::starts_with(prefix)))
  if (length(opt_cols) == 0L) {
    stop("No columns start with prefix '", prefix, "'.", call. = FALSE)
  }

  d <- tibble::as_tibble(data)
  id_col <- ".row_id"
  if (!rlang::quo_is_null(id_q)) {
    id_col <- rlang::as_name(rlang::ensym(id))
  } else {
    d[[id_col]] <- seq_len(nrow(d))
  }
  by_names <- if (has_by) {
    names(dplyr::select(d, {{ by }}))
  } else {
    intersect(as.character(ezrsurvey_default("default_by")), names(d))
  }

  long <- d %>%
    dplyr::select(dplyr::all_of(c(id_col, by_names)),
                  dplyr::all_of(opt_cols)) %>%
    tidyr::pivot_longer(dplyr::all_of(opt_cols),
                        names_to = "option", values_to = "value") %>%
    dplyr::mutate(value = na_blank(.data$value)) %>%
    dplyr::filter(!is.na(.data$value))

  if (clean_names) {
    long <- dplyr::mutate(
      long,
      option = clean_label(stringr::str_remove(.data$option, stringr::fixed(prefix)))
    )
  } else {
    long <- dplyr::mutate(
      long,
      option = stringr::str_remove(.data$option, stringr::fixed(prefix))
    )
  }

  long <- drop_rows(long, "option", drop)

  counts <- long %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(by_names)), .data$option) %>%
    dplyr::summarise(n = dplyr::n_distinct(.data[[id_col]]), .groups = "drop")

  if (length(by_names) > 0L) {
    denom <- long %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(by_names))) %>%
      dplyr::summarise(.denom = dplyr::n_distinct(.data[[id_col]]),
                       .groups = "drop")
    out <- counts %>%
      dplyr::left_join(denom, by = by_names) %>%
      dplyr::mutate(pct = round(.data$n / .data$.denom * 100, digits)) %>%
      dplyr::select(-".denom")
  } else {
    denom <- dplyr::n_distinct(long[[id_col]])
    out <- counts %>%
      dplyr::mutate(pct = round(.data$n / denom * 100, digits))
  }

  out <- order_factor(out, "option", sort = sort)
  tibble::as_tibble(out)
}

#' Summarise a numeric question (mean / median / sd)
#'
#' The numeric counterpart to [calc_percentage()]: a one-liner for the
#' `summarise(mean, median, sd)` blocks used on age and other continuous
#' variables, with optional grouping.
#'
#' @param data A data frame.
#' @param column Numeric column to summarise (unquoted).
#' @param by Optional grouping column(s); see [calc_percentage()].
#' @param na_rm Drop `NA` before summarising. Defaults to `TRUE`.
#' @param weights Survey weighting: `NULL` (default) uses the session scheme from
#'   [set_weights()] if set; `FALSE` forces unweighted; or pass an ad-hoc scheme.
#'   When weighting is active the `mean`, `median` and `sd` become their weighted
#'   versions (`n` stays the unweighted base).
#'
#' @return A [tibble][tibble::tibble] with `n` (non-missing count), `mean`,
#'   `median` and `sd`, one row per group when `by` is supplied.
#'
#' @details
#' The column is passed through [ensure_numeric()] first, so a text age column
#' like `"25 years"` still summarises. `n` counts non-missing values (after that
#' coercion). When a weighting scheme is active the statistics are weighted (and
#' missing values are dropped); `n` remains the unweighted respondent count. For a
#' measure of how precise the `mean` is, pair this with [diagnose()] or
#' [se_mean()].
#'
#' @family summaries
#' @seealso [calc_percentage()] for categorical variables, [diagnose()] for
#'   precision.
#'
#' @examples
#' calc_summary(podracing_survey, demo_age)
#' #> # A tibble: 1 x 4
#' #>       n  mean median    sd
#' #>   <int> <dbl>  <dbl> <dbl>
#' #> 1  1000  32.6     32  11.2
#'
#' calc_summary(podracing_survey, demo_age, by = region)
#' @export
calc_summary <- function(data = NULL, column, by = NULL, na_rm = TRUE,
                         weights = NULL) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(column)),
                            missing(column))
  data <- r$data
  col_name <- col_label(r$cols[[1]])
  col_sym <- rlang::sym(col_name)
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  w <- resolve_weights(data, weights)
  weighted <- !is.null(w)
  if (weighted) data[[".w"]] <- w

  # Salvage numbers from lightly messy text (e.g. "25 years") before summarising.
  data[[col_name]] <- ensure_numeric(data[[col_name]], name = col_name)

  grouped <- if (has_by) dplyr::group_by(data, dplyr::pick({{ by }})) else data

  out <- if (weighted) {
    grouped %>%
      dplyr::summarise(
        n = sum(!is.na(!!col_sym)),
        mean = stats::weighted.mean(!!col_sym, .data$.w, na.rm = na_rm),
        median = wtd_median(!!col_sym, .data$.w),
        sd = wtd_sd(!!col_sym, .data$.w),
        .groups = "drop"
      )
  } else {
    grouped %>%
      dplyr::summarise(
        n = sum(!is.na(!!col_sym)),
        mean = mean(!!col_sym, na.rm = na_rm),
        median = stats::median(!!col_sym, na.rm = na_rm),
        sd = stats::sd(!!col_sym, na.rm = na_rm),
        .groups = "drop"
      )
  }
  tibble::as_tibble(out)
}

#' Percentages for a batch of questions at once
#'
#' Runs [calc_percentage()] over several columns and stacks the results into one
#' tidy table with a `variable` column identifying the source question and a
#' shared `answer` column -- handy for tabulating a whole block of questions
#' (e.g. every `demo_` variable) in a single call.
#'
#' @param data A data frame.
#' @param ... Columns to tabulate, using tidyselect (e.g. `starts_with("demo_")`
#'   or `demo_gender, demo_edu`).
#' @param by,sort,digits,na_rm,drop,weights Passed to [calc_percentage()] (so a
#'   `wpct` column appears when weighting is active, and `drop` removes unwanted
#'   answers from every question).
#'
#' @return A [tibble][tibble::tibble] with `variable`, `answer`, `n`, `pct`
#'   (plus any `by` columns).
#'
#' @details
#' Each selected column is tabulated with [calc_percentage()] and the results are
#' row-bound, with a `variable` column naming the source question and the answers
#' collected into a shared character `answer` column (factor levels differ
#' between questions, so they are coerced to character when stacked). This is the
#' tidy long shape you want for faceted plots or a single export of a whole
#' question block. To send each question to its own Excel tab instead, see
#' [export_xlsx()].
#'
#' @family summaries
#' @seealso [calc_percentage()], [export_xlsx()].
#' @examples
#' calc_percentage_batch(podracing_survey, demo_gender, demo_job)
#' #> # A tibble: 8 x 4
#' #>   variable    answer                n   pct
#' #>   <chr>       <chr>             <int> <dbl>
#' #> 1 demo_gender Female              399    42
#' #> 2 demo_gender Male                525    55
#' #> # ... and so on for each answer of each variable
#'
#' calc_percentage_batch(podracing_survey, starts_with("demo_"))
#' @export
calc_percentage_batch <- function(data = NULL, ..., by = NULL,
                                  sort = c("none", "desc", "asc"),
                                  digits = 0, na_rm = TRUE, drop = NULL,
                                  weights = NULL) {
  r <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- r$data
  sort <- match.arg(sort)
  cols <- names(dplyr::select(data, !!!r$dots))
  if (length(cols) == 0L) {
    stop("Select at least one column to tabulate.", call. = FALSE)
  }
  by_q <- rlang::enquo(by)

  purrr::map_dfr(cols, function(col) {
    res <- rlang::inject(
      calc_percentage(data, !!rlang::sym(col), by = !!by_q,
                      sort = sort, digits = digits, na_rm = na_rm,
                      drop = drop, weights = weights)
    )
    names(res)[names(res) == col] <- "answer"
    res$answer <- as.character(res$answer)
    dplyr::mutate(res, variable = col, .before = 1)
  })
}
