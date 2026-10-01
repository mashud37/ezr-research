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

# Internal: where each value sits in the order the table should use. A margin
# with a registered order sorts by it; one without keeps the order it already
# had, so putting the rows right does not scramble the columns.
order_rank <- function(values, levels = NULL) {
  values <- as.character(values)
  match(values, levels %||% unique(values))
}

# Internal: the answer order a factor column carries, or NULL when the column is
# not a factor. Only answers still present are kept, so a level that was blanked
# or dropped does not come back as an empty row, and an answer the levels do not
# list goes at the end rather than turning into NA.
factor_order <- function(column, answers) {
  if (!is.factor(column)) {
    return(NULL)
  }
  present <- unique(stats::na.omit(as.character(answers)))
  in_order <- levels(column)[levels(column) %in% present]
  c(in_order, setdiff(present, in_order))
}

# Internal: the crosstab cells in long form, under the fixed names `.x`, `.y`
# and `.value`. The counting runs on a frame built here from only the columns it
# needs, so a survey column that happens to be called `value` or `n` cannot
# collide with the names the counting uses. crosstab_banner() reads this
# directly for the same reason.
crosstab_long <- function(data, x_name, y_name, cell, value_name, fn, digits,
                          na_rm, drop, weights) {
  w <- resolve_weights(data, weights)
  weighted <- !is.null(w)

  d <- tibble::tibble(.x = data[[x_name]], .y = data[[y_name]])
  if (!is.null(value_name)) d$.v <- data[[value_name]]
  if (weighted) d$.w <- w
  if (na_rm) {
    d$.x <- na_blank(d$.x)
    d$.y <- na_blank(d$.y)
    d <- d[!is.na(d$.x) & !is.na(d$.y), , drop = FALSE]
  }
  d <- drop_rows(d, ".x", drop)
  d <- drop_rows(d, ".y", drop)

  if (!is.null(value_name)) {
    if (weighted && !identical(fn, mean)) {
      warning("Weighted crosstab aggregates `value` with the weighted mean; ",
              "`fn` is ignored.", call. = FALSE)
    }
    out <- d %>%
      dplyr::group_by(.data$.x, .data$.y) %>%
      dplyr::summarise(
        .value = if (weighted) {
          round(summarise_cell_wtd(.data$.v, .data$.w, na_rm), digits)
        } else {
          round(summarise_cell(.data$.v, fn, na_rm), digits)
        },
        .groups = "drop"
      )
  } else {
    counts <- if (weighted) {
      d %>%
        dplyr::group_by(.data$.x, .data$.y) %>%
        dplyr::summarise(.n = sum(.data$.w), .groups = "drop")
    } else {
      dplyr::count(d, .data$.x, .data$.y, name = ".n")
    }
    out <- switch(
      cell,
      count = dplyr::mutate(counts, .value = round(.data$.n)),
      row_pct = counts %>%
        dplyr::group_by(.data$.x) %>%
        dplyr::mutate(.value = round(.data$.n / sum(.data$.n) * 100, digits)) %>%
        dplyr::ungroup(),
      col_pct = counts %>%
        dplyr::group_by(.data$.y) %>%
        dplyr::mutate(.value = round(.data$.n / sum(.data$.n) * 100, digits)) %>%
        dplyr::ungroup(),
      total_pct = dplyr::mutate(
        counts, .value = round(.data$.n / sum(.data$.n) * 100, digits))
    )
    out <- out[c(".x", ".y", ".value")]
  }

  # A registered order wins; a factor's own levels come next.
  x_levels <- order_for(x_name) %||% factor_order(data[[x_name]], out$.x)
  y_levels <- order_for(y_name) %||% factor_order(data[[y_name]], out$.y)
  if (!is.null(x_levels)) out$.x <- factor(out$.x, levels = x_levels)
  if (!is.null(y_levels)) out$.y <- factor(out$.y, levels = y_levels)
  # Levels alone reach the charts and nothing else: a printed or exported table
  # carries none, and tidyr names new columns in order of first appearance, so
  # the rows are sorted too.
  if (!is.null(x_levels) || !is.null(y_levels)) {
    out <- out[order(order_rank(out$.x, x_levels),
                     order_rank(out$.y, y_levels)), , drop = FALSE]
  }
  tibble::as_tibble(out)
}

#' Cross-tabulate two survey questions
#'
#' Builds a crosstab from two categorical columns: `x` forms the rows and `y` the
#' columns. The cell contents are chosen with `cell` -- counts or row/column/total
#' percentages -- or, when a numeric `value` column is supplied, an aggregate of
#' that column (e.g. the mean spend) for each `x` by `y` combination. Registered
#' orders (see [register_order()]) are applied to `x` and `y` automatically, and
#' a factor column keeps its own level order when no order is registered.
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
#' @param drop Optional character vector of answer values to remove from both `x`
#'   and `y` before tabulating (e.g. `c("Other")`), matched case-insensitively.
#'   Defaults to the `drop_answers` option. See [drop_items()].
#' @param weights Survey weighting: `NULL` (default) uses the session scheme from
#'   [set_weights()] if set; `FALSE` forces unweighted; or pass an ad-hoc scheme.
#'   When weighting is active the cells default to weighted values -- weighted
#'   counts, weighted percentages, or (for a numeric `value`) the weighted mean.
#'
#' @return A [tibble][tibble::tibble]: wide (x plus one column per y level) or
#'   long (`x`, `y`, `value`). The long form refuses an `x` or `y` that is itself
#'   called `value`, since the two columns would share a name.
#'
#' @details
#' Choose what the cells mean with `cell`: `"row_pct"` makes each **row** sum to
#' 100 (the distribution of `y` within each `x`), `"col_pct"` makes each
#' **column** sum to 100, `"total_pct"` is the share of the whole table, and
#' `"count"` is the raw frequency. Supplying a numeric `value` switches the cells
#' to an aggregate of that column -- by default the mean -- which answers
#' questions like "what is the average NPS for each region by gender?". Blanks
#' and non-answers in `x`/`y` are dropped when `na_rm = TRUE`. Any registered
#' orders ([register_order()]) set the row/column ordering automatically; a
#' factor without one keeps its own level order; anything else stays in data
#' order.
#'
#' @family summaries
#' @seealso [calc_percentage()], [compare_values()], [register_order()].
#' @examples
#' # counts
#' crosstab(podracing_survey, demo_gender, region)
#'
#' # row percentages: gender split within each region (each row ~ 100)
#' crosstab(podracing_survey, region, demo_gender, cell = "row_pct")
#'
#' # mean NPS for each region x gender cell
#' crosstab(podracing_survey, region, demo_gender, value = nps_value, fn = mean)
#' @export
crosstab <- function(data = NULL, x, y, cell = c("count", "row_pct", "col_pct",
                                          "total_pct"),
                     value = NULL, fn = mean, wide = TRUE, digits = NULL,
                     na_rm = TRUE, drop = NULL, weights = NULL) {
  r <- resolve_data_columns(rlang::enquo(data),
                            list(rlang::enquo(x), rlang::enquo(y)), missing(y))
  data <- r$data
  cell <- match.arg(cell)
  x_name <- col_label(r$cols[[1]], data)
  y_name <- col_label(r$cols[[2]], data)
  value_name <- NULL
  if (!rlang::quo_is_null(rlang::enquo(value))) {
    value_name <- rlang::as_name(rlang::ensym(value))
  }
  if (is.null(digits)) digits <- if (is.null(value_name)) 0 else 2

  out <- crosstab_long(data, x_name, y_name, cell, value_name, fn, digits,
                       na_rm, drop, weights)

  if (wide) {
    # A `y` with an order is a factor by now, and its columns follow the levels;
    # one without keeps the order its answers first appear in.
    out <- tidyr::pivot_wider(out, names_from = ".y", values_from = ".value",
                              names_sort = is.factor(out$.y))
    names(out)[names(out) == ".x"] <- x_name
    return(out)
  }
  if ("value" %in% c(x_name, y_name)) {
    stop("crosstab(wide = FALSE) puts the cells in a column called `value`, ",
         "which is also the name of a question here. Rename that column, or ",
         "use wide = TRUE.", call. = FALSE)
  }
  names(out) <- c(x_name, y_name, "value")
  out
}
