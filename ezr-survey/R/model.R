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
#' @return A [tibble][tibble::tibble] with `n` (valid responses), `nps` (an
#'   integer from -100 to 100), the three group shares (`pct_detractors`,
#'   `pct_passives`, `pct_promoters`) and the counts behind them (`detractors`,
#'   `passives`, `promoters`), one row per group when `by` is given. The shares
#'   come first because they are what a report quotes.
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
#' The three group counts and shares are reported alongside the score because a
#' single NPS hides how it was reached: +20 from 40% promoters and 20%
#' detractors is a different picture from +20 with 25% and 5%. Counts are always
#' unweighted respondent counts; the shares follow `nps`, so they are weighted
#' when a weighting scheme is active. All three shares and `nps` are rounded to
#' whole numbers independently, so `pct_promoters - pct_detractors` can land one
#' point away from `nps`; the identity holds exactly before rounding.
#'
#' @family modelling
#' @seealso [nps_group()], [plot_nps()], [plot_nps_gauge()].
#' @examples
#' calc_nps(podracing_survey, nps_value)
#'
#' calc_nps(podracing_survey, nps_value, by = region)
#' @export
calc_nps <- function(data = NULL, value, by = NULL, weights = NULL) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(value)),
                            missing(value))
  data <- r$data
  col_name <- col_label(r$cols[[1]], data)
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  w <- resolve_weights(data, weights)

  d <- data
  d[[".w"]] <- if (is.null(w)) rep(1, nrow(d)) else w
  d[[col_name]] <- ensure_numeric(d[[col_name]], name = col_name)
  d[[".nps_group"]] <- nps_group(d[[col_name]])
  d <- dplyr::filter(d, !is.na(.data$.nps_group))

  grouped <- if (has_by) dplyr::group_by(d, dplyr::pick({{ by }})) else d

  out <- grouped %>%
    dplyr::summarise(
      n = dplyr::n(),
      nps = round(stats::weighted.mean(.data$.nps_group, .data$.w) * 100),
      pct_detractors = round(
        stats::weighted.mean(.data$.nps_group == -1, .data$.w) * 100),
      pct_passives = round(
        stats::weighted.mean(.data$.nps_group == 0, .data$.w) * 100),
      pct_promoters = round(
        stats::weighted.mean(.data$.nps_group == 1, .data$.w) * 100),
      detractors = sum(.data$.nps_group == -1),
      passives = sum(.data$.nps_group == 0),
      promoters = sum(.data$.nps_group == 1),
      .groups = "drop"
    )
  tibble::as_tibble(out)
}

# Internal: the complete numeric cases every importance method works from.
importance_frame <- function(df, outcome, predictors) {
  df %>%
    dplyr::select(dplyr::all_of(c(outcome, predictors))) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric)) %>%
    stats::na.omit()
}

# Internal: put any importance measure onto the rwa scale, summing to 100, so
# every method returns numbers a reader can compare and plot_ipm can draw.
rescale_importance <- function(features, values) {
  values <- as.numeric(values)
  values[is.na(values) | values < 0] <- 0
  total <- sum(values)
  if (total == 0) {
    stop("No predictor carries any signal; importance is undefined.",
         call. = FALSE)
  }
  tibble::tibble(feature = features, importance = values / total * 100)
}

# Internal: relative weights analysis via the rwa package.
rwa_importance <- function(df, outcome, predictors) {
  if (!requireNamespace("rwa", quietly = TRUE)) {
    stop("Package 'rwa' is required for method = \"rwa\". ",
         "Install it with install.packages('rwa').", call. = FALSE)
  }
  d <- importance_frame(df, outcome, predictors)
  r <- rwa::rwa(d, outcome = outcome, predictors = predictors)
  tibble::tibble(
    feature = r$result$Variables,
    importance = r$result$Rescaled.RelWeight
  )
}

# Internal: random-forest permutation importance (%IncMSE), which picks up
# non-linear and interaction effects that relative weights cannot see.
forest_importance <- function(df, outcome, predictors) {
  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required for method = \"forest\". ",
         "Install it with install.packages('randomForest').", call. = FALSE)
  }
  d <- importance_frame(df, outcome, predictors)
  fit <- randomForest::randomForest(x = d[predictors], y = d[[outcome]],
                                    importance = TRUE)
  raw <- randomForest::importance(fit, type = 1)
  rescale_importance(rownames(raw), raw[, 1])
}

# Internal: absolute correlation with the outcome, rescaled. Needs no suggested
# package, so it always works.
correlation_importance <- function(df, outcome, predictors) {
  d <- importance_frame(df, outcome, predictors)
  raw <- vapply(predictors, function(p) abs(stats::cor(d[[p]], d[[outcome]])),
                numeric(1))
  rescale_importance(predictors, raw)
}

# Internal: dispatch to the chosen importance method, always returning the
# strongest driver first so the three methods read the same way.
compute_importance <- function(df, outcome, predictors, method) {
  out <- if (method == "rwa") {
    rwa_importance(df, outcome, predictors)
  } else if (method == "forest") {
    forest_importance(df, outcome, predictors)
  } else {
    correlation_importance(df, outcome, predictors)
  }
  dplyr::arrange(out, dplyr::desc(.data$importance))
}

#' Driver importance
#'
#' Ranks how much each predictor drives an outcome such as the NPS rating, as
#' importance scores summing to 100. Relative weights analysis is the default;
#' a random forest and a plain correlation are available as alternatives.
#'
#' @param data A data frame.
#' @param outcome The outcome column (unquoted), e.g. `nps_value`.
#' @param predictors The predictor columns, using tidyselect (e.g.
#'   `starts_with("ratings_")`).
#' @param method How to measure importance. `"rwa"` (default) is relative
#'   weights analysis via [rwa::rwa()]; `"forest"` is random-forest permutation
#'   importance via [randomForest::randomForest()]; `"correlation"` is the
#'   absolute correlation with the outcome. See Details.
#' @param recode If `TRUE` (default), character predictor columns are mapped to
#'   1-5 with [recode_likert()]; numeric columns are left as-is.
#' @param likert_levels Scale wordings passed to [recode_likert()] when
#'   recoding.
#'
#' @return A [tibble][tibble::tibble] with `feature` and `importance`, the
#'   latter rescaled to sum to 100 whichever `method` produced it, strongest
#'   driver first.
#'
#' @details
#' All three methods answer the same question and are scaled the same way, so
#' each feature's `importance` reads as "this feature accounts for X% of what
#' drives the outcome" and any of them can be fed to [plot_ipm()]. They differ in
#' what they can see:
#'
#' * `"rwa"`, relative weights analysis (Johnson's epsilon), shares out the
#'   linear model's explained variance between correlated predictors, which
#'   ordinary regression coefficients handle poorly. This is the default because
#'   rating batteries are almost always heavily correlated.
#' * `"forest"` grows a random forest and measures how much prediction error
#'   rises when each predictor is permuted, so it picks up non-linear effects and
#'   interactions that relative weights cannot. It is the useful cross-check: if
#'   a feature ranks high here and low under `"rwa"`, its effect is not linear.
#'   Being a random method, it moves a little between runs; call [set.seed()]
#'   first for a figure you intend to publish.
#' * `"correlation"` is the crude one, ignoring the other predictors entirely, so
#'   correlated features double-count. Its merit is that it needs no suggested
#'   package and cannot fail to converge, which makes it a reasonable sanity
#'   check on the other two.
#'
#' Only complete cases are used. Worded rating columns are recoded to 1-5
#' automatically (`recode = TRUE`). Negative importances (which permutation
#' importance can produce for a predictor that is pure noise) are floored at
#' zero before rescaling. Most users call [ipm_model()], which pairs this with
#' performance for the importance/performance matrix.
#'
#' @family modelling
#' @seealso [ipm_model()], [plot_ipm()].
#' @examplesIf requireNamespace("rwa", quietly = TRUE) && requireNamespace("randomForest", quietly = TRUE)
#' calc_importance(podracing_survey, nps_value, starts_with("ratings_"))
#'
#' # a cross-check that can see non-linear effects
#' set.seed(1)
#' calc_importance(podracing_survey, nps_value, starts_with("ratings_"),
#'                 method = "forest")
#' @export
calc_importance <- function(data = NULL, outcome, predictors,
                            method = c("rwa", "forest", "correlation"),
                            recode = TRUE,
                            likert_levels = c("Very bad", "Bad", "Ok",
                                              "Good", "Very good")) {
  r <- resolve_data_columns(rlang::enquo(data),
                            list(rlang::enquo(outcome), rlang::enquo(predictors)),
                            missing(predictors))
  data <- r$data
  method <- match.arg(method)
  out_name <- col_label(r$cols[[1]], data)
  pred_names <- names(dplyr::select(data, !!r$cols[[2]]))
  if (length(pred_names) == 0L) {
    stop("No predictor columns selected.", call. = FALSE)
  }
  if (recode) {
    data <- dplyr::mutate(data, dplyr::across(dplyr::all_of(pred_names), function(col) {
      if (is.numeric(col)) col else recode_likert(col, levels = likert_levels)
    }))
  }
  compute_importance(data, out_name, pred_names, method)
}

# Bucket a 1-5 mean rating into its performance band by integer part, so a mean
# of 3.57 sits in band 3 (the band it is actually inside) rather than rounding
# up to 4 and picking up the next colour.
cut_perf_band <- function(performance) {
  factor(floor(performance), levels = as.character(1:5))
}

#' Build an importance / performance model
#'
#' Combines driver **importance** (against `outcome`) with
#' feature **performance** (mean rating) into the tidy table consumed by
#' [plot_ipm()]. Worded rating columns are recoded to 1-5 automatically.
#'
#' @param data A data frame.
#' @param outcome The outcome column (unquoted), e.g. `nps_value`.
#' @param rating_prefix Column-name prefix identifying the rating block, e.g.
#'   `"ratings_"`.
#' @param method How to measure importance, passed to [calc_importance()].
#'   Defaults to `"rwa"`.
#' @param recode If `TRUE` (default), character rating columns are mapped to
#'   1-5 with [recode_likert()]; numeric columns are left as-is.
#' @param likert_levels Scale wordings passed to [recode_likert()] when
#'   recoding.
#'
#' @return A [tibble][tibble::tibble] with `feature`, `importance`,
#'   `performance` and `perf_class` (the performance band as a 1-5 factor, from
#'   its integer part so a 3.57 mean sits in band 3, used for colouring).
#'
#' @details
#' An importance/performance model answers two questions per feature at once:
#' *how much does it drive the outcome* (importance, via [calc_importance()]) and
#' *how well are we doing on it* (performance, the mean 1--5 rating). Plotting one
#' against the other ([plot_ipm()]) reveals priorities: high-importance,
#' low-performance features are where to invest. Worded rating columns are mapped
#' to 1--5 with [recode_likert()] automatically (`recode = TRUE`); the prefix is
#' stripped from feature names; and `perf_class` buckets performance into a 1--5
#' factor by its integer part (a 3.57 mean is band 3, not 4) for colouring.
#' Importance comes from [calc_importance()], so `method` chooses between
#' relative weights (the default, requiring the suggested `rwa` package), a
#' random forest and a plain correlation.
#'
#' @family modelling
#' @seealso [calc_importance()], [plot_ipm()], [compare_values()].
#' @examplesIf requireNamespace("rwa", quietly = TRUE)
#' ipm_model(podracing_survey, nps_value, "ratings_")
#' @export
ipm_model <- function(data = NULL, outcome, rating_prefix,
                      method = c("rwa", "forest", "correlation"),
                      recode = TRUE,
                      likert_levels = c("Very bad", "Bad", "Ok",
                                        "Good", "Very good")) {
  r <- resolve_data_columns(rlang::enquo(data),
                            list(rlang::enquo(outcome),
                                 rlang::enquo(rating_prefix)),
                            missing(rating_prefix))
  data <- r$data
  method <- match.arg(method)
  out_name <- col_label(r$cols[[1]], data)
  rating_prefix <- rlang::eval_tidy(r$cols[[2]])
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

  importance <- compute_importance(d, out_name, rate_cols, method)

  dplyr::left_join(importance, performance, by = "feature") %>%
    dplyr::mutate(
      feature = clean_label(stringr::str_remove(.data$feature,
                                                stringr::fixed(rating_prefix))),
      perf_class = cut_perf_band(.data$performance)
    ) %>%
    tibble::as_tibble()
}
