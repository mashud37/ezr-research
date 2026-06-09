#' Net Promoter Score
#'
#' Computes NPS from a 0-10 recommendation question. The score is
#' `% promoters - % detractors`, equivalently `100 * mean(nps_group(x))` over the
#' signed `-1/0/1` coding (see [nps_group()]).
#'
#' @param data A data frame.
#' @param value The 0-10 recommendation column (unquoted).
#' @param by Optional grouping column(s); see [calc_percentage()].
#' @param weights Survey weighting: `NULL` (default) uses the session scheme from
#'   [set_weights()] if set; `FALSE` forces unweighted; or pass an ad-hoc scheme.
#'   When weighting is active `nps` is the weighted score (`n` stays the
#'   unweighted base).
#'
#' @return A [tibble][tibble::tibble] with `n` (valid responses) and `nps` (an
#'   integer from -100 to 100), one row per group when `by` is given.
#'
#' @details
#' Respondents are bucketed by [nps_group()] into detractors (0--6), passives
#' (7--8) and promoters (9--10); the score is the percentage of promoters minus
#' the percentage of detractors, which equals `100 * mean()` of the signed
#' `-1/0/1` coding. Missing or out-of-range scores are dropped before the mean.
#' Text answers are coerced with [ensure_numeric()]. Use [plot_nps()] for the
#' full 0--10 distribution chart and [plot_nps_gauge()] for a single-number
#' gauge.
#'
#' @family modelling
#' @seealso [nps_group()], [plot_nps()], [plot_nps_gauge()].
#' @examples
#' calc_nps(consumer_survey, nps_value)
#' #> # A tibble: 1 x 2
#' #>       n   nps
#' #>   <int> <dbl>
#' #> 1  1000     3
#'
#' calc_nps(consumer_survey, nps_value, by = region)
#' @export
calc_nps <- function(data = NULL, value, by = NULL, weights = NULL) {
  data <- resolve_data(data)
  col_name <- rlang::as_name(rlang::ensym(value))
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  w <- resolve_weights(data, weights)
  weighted <- !is.null(w)

  d <- data
  if (weighted) d[[".w"]] <- w
  d[[col_name]] <- ensure_numeric(d[[col_name]], name = col_name)
  d[[".nps_group"]] <- nps_group(d[[col_name]])
  d <- dplyr::filter(d, !is.na(.data$.nps_group))

  grouped <- if (has_by) dplyr::group_by(d, dplyr::pick({{ by }})) else d

  out <- if (weighted) {
    grouped %>%
      dplyr::summarise(
        n = dplyr::n(),
        nps = round(stats::weighted.mean(.data$.nps_group, .data$.w) * 100),
        .groups = "drop"
      )
  } else {
    grouped %>%
      dplyr::summarise(
        n = dplyr::n(),
        nps = round(mean(.data$.nps_group) * 100),
        .groups = "drop"
      )
  }
  tibble::as_tibble(out)
}

# Internal: relative weights analysis via the rwa package.
rwa_importance <- function(df, outcome, predictors) {
  if (!requireNamespace("rwa", quietly = TRUE)) {
    stop("Package 'rwa' is required for importance analysis. ",
         "Install it with install.packages('rwa').", call. = FALSE)
  }
  d <- df %>%
    dplyr::select(dplyr::all_of(c(outcome, predictors))) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric)) %>%
    stats::na.omit()
  r <- rwa::rwa(d, outcome = outcome, predictors = predictors)
  tibble::tibble(
    feature = r$result$Variables,
    importance = r$result$Rescaled.RelWeight
  )
}

#' Driver importance via relative weights analysis
#'
#' Thin wrapper around [rwa::rwa()] that returns the rescaled relative weights
#' (importance, summing to ~100) of a set of predictors against an outcome such
#' as the NPS rating. Requires the suggested `rwa` package.
#'
#' @param data A data frame.
#' @param outcome The outcome column (unquoted), e.g. `nps_value`.
#' @param predictors The predictor columns, using tidyselect (e.g.
#'   `starts_with("ratings_")`).
#'
#' @return A [tibble][tibble::tibble] with `feature` and `importance`.
#'
#' @details
#' Relative weights analysis (Johnson's epsilon) shares out the model's explained
#' variance between correlated predictors, which ordinary regression
#' coefficients handle poorly. The weights are rescaled to sum to ~100, so each
#' feature's `importance` reads as "this feature accounts for X% of what drives
#' the outcome". Only complete cases are used, and all columns are coerced to
#' numeric (recode worded ratings with [recode_likert()] first if needed). Most
#' users call [ipm_model()], which pairs this with performance for the
#' importance/performance matrix.
#'
#' @family modelling
#' @seealso [ipm_model()], [plot_ipm()].
#' @examplesIf requireNamespace("rwa", quietly = TRUE)
#' # predictors must be numeric -- recode worded ratings first (or use ipm_model())
#' d <- consumer_survey
#' d[paste0("r_", 1:5)] <- lapply(d[grep("^ratings_", names(d))], recode_likert)
#' calc_importance(d, nps_value, dplyr::starts_with("r_"))
#' @export
calc_importance <- function(data = NULL, outcome, predictors) {
  data <- resolve_data(data)
  out_name <- rlang::as_name(rlang::ensym(outcome))
  pred_names <- names(dplyr::select(data, {{ predictors }}))
  if (length(pred_names) == 0L) {
    stop("No predictor columns selected.", call. = FALSE)
  }
  rwa_importance(data, out_name, pred_names)
}

#' Build an importance / performance model
#'
#' Combines driver **importance** (relative weights against `outcome`) with
#' feature **performance** (mean rating) into the tidy table consumed by
#' [plot_ipm()]. Worded rating columns are recoded to 1-5 automatically.
#'
#' @param data A data frame.
#' @param outcome The outcome column (unquoted), e.g. `nps_value`.
#' @param rating_prefix Column-name prefix identifying the rating block, e.g.
#'   `"ratings_"`.
#' @param recode If `TRUE` (default), character rating columns are mapped to
#'   1-5 with [recode_likert()]; numeric columns are left as-is.
#' @param likert_levels Scale wordings passed to [recode_likert()] when
#'   recoding.
#'
#' @return A [tibble][tibble::tibble] with `feature`, `importance`,
#'   `performance` and `perf_class` (the rounded performance as a 1-5 factor,
#'   used for colouring).
#'
#' @details
#' An importance/performance model answers two questions per feature at once:
#' *how much does it drive the outcome* (importance, via [calc_importance()]) and
#' *how well are we doing on it* (performance, the mean 1--5 rating). Plotting one
#' against the other ([plot_ipm()]) reveals priorities: high-importance,
#' low-performance features are where to invest. Worded rating columns are mapped
#' to 1--5 with [recode_likert()] automatically (`recode = TRUE`); the prefix is
#' stripped from feature names; and `perf_class` buckets performance into a 1--5
#' factor for colouring. Requires the suggested `rwa` package.
#'
#' @family modelling
#' @seealso [calc_importance()], [plot_ipm()], [compare_values()].
#' @examplesIf requireNamespace("rwa", quietly = TRUE)
#' ipm_model(consumer_survey, nps_value, "ratings_")
#' @export
ipm_model <- function(data = NULL, outcome, rating_prefix, recode = TRUE,
                      likert_levels = c("Very bad", "Bad", "Ok",
                                        "Good", "Very good")) {
  data <- resolve_data(data)
  out_name <- rlang::as_name(rlang::ensym(outcome))
  rate_cols <- names(dplyr::select(data, dplyr::starts_with(rating_prefix)))
  if (length(rate_cols) == 0L) {
    stop("No columns start with prefix '", rating_prefix, "'.", call. = FALSE)
  }

  d <- data
  if (recode) {
    d <- dplyr::mutate(d, dplyr::across(dplyr::all_of(rate_cols), function(col) {
      if (is.numeric(col)) col else recode_likert(col, levels = likert_levels)
    }))
  }
  d <- dplyr::mutate(d, dplyr::across(dplyr::all_of(c(out_name, rate_cols)),
                                      ~ ensure_numeric(.x, quiet = TRUE)))

  performance <- d %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(rate_cols),
                                   ~ mean(.x, na.rm = TRUE))) %>%
    tidyr::pivot_longer(dplyr::everything(),
                        names_to = "feature", values_to = "performance")

  importance <- rwa_importance(d, out_name, rate_cols)

  dplyr::left_join(importance, performance, by = "feature") %>%
    dplyr::mutate(
      feature = clean_label(stringr::str_remove(.data$feature,
                                                stringr::fixed(rating_prefix))),
      perf_class = factor(round(.data$performance),
                          levels = as.character(1:5))
    ) %>%
    tibble::as_tibble()
}
