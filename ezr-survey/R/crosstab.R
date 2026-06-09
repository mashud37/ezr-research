# Internal: na.rm-aware summary of a numeric vector with an arbitrary function.
summarise_cell <- function(x, fn, na_rm) {
  x <- ensure_numeric(x, quiet = TRUE)
  if (na_rm) x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  fn(x)
}

# Internal: na.rm-aware weighted mean of a numeric cell.
summarise_cell_wtd <- function(x, w, na_rm) {
  x <- ensure_numeric(x, quiet = TRUE)
  if (na_rm) {
    ok <- !is.na(x); x <- x[ok]; w <- w[ok]
  }
  if (length(x) == 0L) return(NA_real_)
  stats::weighted.mean(x, w)
}

#' Cross-tabulate two survey questions
#'
#' Builds a crosstab from two categorical columns: `x` forms the rows and `y` the
#' columns. The cell contents are chosen with `cell` -- counts or row/column/total
#' percentages -- or, when a numeric `value` column is supplied, an aggregate of
#' that column (e.g. the mean spend) for each `x` by `y` combination. Registered
#' orders (see [register_order()]) are applied to `x` and `y` automatically.
#'
#' @param data A data frame.
#' @param x Row variable (unquoted).
#' @param y Column variable (unquoted).
#' @param cell What to put in each cell when `value` is not given: `"count"`
#'   (default), `"row_pct"`, `"col_pct"` or `"total_pct"`.
#' @param value Optional numeric column (unquoted) to aggregate per cell instead
#'   of counting.
#' @param fn Aggregation function used with `value`. Default [mean()].
#' @param wide If `TRUE` (default), return one row per `x` with a column per `y`
#'   level; if `FALSE`, return the tidy long form.
#' @param digits Decimal places for percentage / aggregated cells. Default `0`
#'   for percentages, `2` when `value` is supplied.
#' @param na_rm Drop blanks / non-answers in `x`, `y` (and `NA` in `value`).
#'   Default `TRUE`.
#' @param weights Survey weighting: `NULL` (default) uses the session scheme from
#'   [set_weights()] if set; `FALSE` forces unweighted; or pass an ad-hoc scheme.
#'   When weighting is active the cells default to weighted values -- weighted
#'   counts, weighted percentages, or (for a numeric `value`) the weighted mean.
#'
#' @return A [tibble][tibble::tibble]: wide (x plus one column per y level) or
#'   long (`x`, `y`, `value`).
#'
#' @details
#' Choose what the cells mean with `cell`: `"row_pct"` makes each **row** sum to
#' 100 (the distribution of `y` within each `x`), `"col_pct"` makes each
#' **column** sum to 100, `"total_pct"` is the share of the whole table, and
#' `"count"` is the raw frequency. Supplying a numeric `value` switches the cells
#' to an aggregate of that column -- by default the mean -- which answers
#' questions like "what is the average NPS for each region by gender?". Blanks
#' and non-answers in `x`/`y` are dropped when `na_rm = TRUE`, and any registered
#' orders ([register_order()]) set the row/column ordering automatically.
#'
#' @family summaries
#' @seealso [calc_percentage()], [compare_values()], [register_order()].
#' @examples
#' # counts
#' crosstab(consumer_survey, demo_gender, region)
#'
#' # row percentages: gender split within each region (each row ~ 100)
#' crosstab(consumer_survey, region, demo_gender, cell = "row_pct")
#'
#' # mean NPS for each region x gender cell
#' crosstab(consumer_survey, region, demo_gender, value = nps_value, fn = mean)
#' @export
crosstab <- function(data = NULL, x, y, cell = c("count", "row_pct", "col_pct",
                                          "total_pct"),
                     value = NULL, fn = mean, wide = TRUE, digits = NULL,
                     na_rm = TRUE, weights = NULL) {
  data <- resolve_data(data)
  cell <- match.arg(cell)
  x_name <- rlang::as_name(rlang::ensym(x))
  y_name <- rlang::as_name(rlang::ensym(y))
  value_q <- rlang::enquo(value)
  has_value <- !rlang::quo_is_null(value_q)
  if (is.null(digits)) digits <- if (has_value) 2 else 0

  w <- resolve_weights(data, weights)
  weighted <- !is.null(w)

  d <- tibble::as_tibble(data)
  if (weighted) d[[".w"]] <- w
  if (na_rm) {
    d[[x_name]] <- na_blank(d[[x_name]])
    d[[y_name]] <- na_blank(d[[y_name]])
    d <- d[!is.na(d[[x_name]]) & !is.na(d[[y_name]]), , drop = FALSE]
  }

  if (has_value) {
    value_name <- rlang::as_name(rlang::ensym(value))
    if (weighted && !identical(fn, mean)) {
      warning("Weighted crosstab aggregates `value` with the weighted mean; ",
              "`fn` is ignored.", call. = FALSE)
    }
    out <- d %>%
      dplyr::group_by(.data[[x_name]], .data[[y_name]]) %>%
      dplyr::summarise(
        value = if (weighted) {
          round(summarise_cell_wtd(.data[[value_name]], .data$.w, na_rm), digits)
        } else {
          round(summarise_cell(.data[[value_name]], fn, na_rm), digits)
        },
        .groups = "drop"
      )
  } else {
    counts <- if (weighted) {
      d %>%
        dplyr::group_by(.data[[x_name]], .data[[y_name]]) %>%
        dplyr::summarise(n = sum(.data$.w), .groups = "drop")
    } else {
      dplyr::count(d, .data[[x_name]], .data[[y_name]], name = "n")
    }
    out <- switch(
      cell,
      count = dplyr::mutate(counts, value = round(.data$n)),
      row_pct = counts %>%
        dplyr::group_by(.data[[x_name]]) %>%
        dplyr::mutate(value = round(.data$n / sum(.data$n) * 100, digits)) %>%
        dplyr::ungroup(),
      col_pct = counts %>%
        dplyr::group_by(.data[[y_name]]) %>%
        dplyr::mutate(value = round(.data$n / sum(.data$n) * 100, digits)) %>%
        dplyr::ungroup(),
      total_pct = dplyr::mutate(
        counts, value = round(.data$n / sum(.data$n) * 100, digits))
    )
    out <- dplyr::select(out, dplyr::all_of(c(x_name, y_name)), "value")
  }

  # Apply registered orders to row/column variables, if any.
  x_levels <- order_for(x_name)
  y_levels <- order_for(y_name)
  if (!is.null(x_levels)) out[[x_name]] <- factor(out[[x_name]], levels = x_levels)
  if (!is.null(y_levels)) out[[y_name]] <- factor(out[[y_name]], levels = y_levels)

  if (wide) {
    out <- tidyr::pivot_wider(out, names_from = dplyr::all_of(y_name),
                              values_from = "value")
  }
  tibble::as_tibble(out)
}
