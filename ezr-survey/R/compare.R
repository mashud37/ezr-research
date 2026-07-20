#' Compare a metric between two datasets (e.g. two events or waves)
#'
#' Joins a `current` and a `previous` table on a key column and computes the
#' difference of a metric -- for example feature `performance` from two
#' [ipm_model()] outputs, or `pct` from two [calc_percentage()] tables for two
#' events. The result feeds straight into [plot_diff()].
#'
#' @param current,previous Data frames sharing a key column and a metric column.
#' @param by Name of the key column to join on. Default `"feature"`.
#' @param value Name of the metric column to compare. Default `"performance"`.
#'
#' @return A [tibble][tibble::tibble] with the key column, `previous`, `current`
#'   and `difference` (`current - previous`).
#'
#' @details
#' The join is a left join keyed on `by` with `previous` on the left, so the row
#' set follows the previous period and `difference` is `current - previous` (a
#' positive number means it went up). Keys present only in `current` are dropped;
#' keys missing from `current` get an `NA` difference. The inputs are deliberately
#' generic two-column-or-more tables, so the same function compares feature
#' `performance` from two [ipm_model()] runs, `pct` from two [calc_percentage()]
#' tables for two events, or any other keyed metric.
#'
#' @family compare
#' @seealso [plot_diff()], [ipm_model()], [calc_percentage()].
#' @examples
#' a <- data.frame(feature = c("price", "quality"), performance = c(3.1, 4.2))
#' b <- data.frame(feature = c("price", "quality"), performance = c(2.8, 4.4))
#' compare_values(current = b, previous = a)
#' #> # A tibble: 2 x 4
#' #>   feature previous current difference
#' #>   <chr>      <dbl>   <dbl>      <dbl>
#' #> 1 price        3.1     2.8      -0.3
#' #> 2 quality      4.2     4.4       0.2
#' @export
compare_values <- function(current, previous, by = "feature",
                           value = "performance") {
  if (!all(c(by, value) %in% names(current)) ||
      !all(c(by, value) %in% names(previous))) {
    stop("Both `current` and `previous` need columns '", by, "' and '",
         value, "'.", call. = FALSE)
  }
  cur <- current[, c(by, value)]
  names(cur)[names(cur) == value] <- "current"
  prev <- previous[, c(by, value)]
  names(prev)[names(prev) == value] <- "previous"

  out <- dplyr::left_join(prev, cur, by = by)
  out$difference <- out$current - out$previous
  tibble::as_tibble(out)
}

#' Diverging bar chart of differences
#'
#' Plots a column of differences (e.g. from [compare_values()]) as a sorted,
#' diverging horizontal bar chart: positives in green, negatives in amber, signed
#' value labels, and a zero reference line. This is the standard "what improved,
#' what slipped" change chart.
#'
#' @param data A data frame with a label column and a difference column.
#' @param label Category/label column (unquoted). Default `feature`.
#' @param difference Difference column (unquoted). Default `difference`.
#' @param limits Numeric length-2 y-axis limits. If `NULL` (default), a symmetric
#'   range around zero is chosen from the data.
#' @param digits Decimal places for the value labels. Default `2`.
#' @param pos_colour,neg_colour Bar colours for positive / negative differences.
#' @param title Optional plot title.
#'
#' @return A ggplot object.
#'
#' @details
#' Bars are sorted by the difference and drawn horizontally (largest gain at the
#' top), coloured green for positive and amber for negative changes, with signed
#' value labels (`+0.20` / `-0.30`) nudged to sit just outside each bar and a
#' zero reference line. When `limits` is `NULL` the y-axis is made symmetric
#' around zero from the data so gains and losses are visually comparable; pass
#' `limits = c(-1, 1)` (say) to fix it. Feed it the output of [compare_values()],
#' or any data frame with a label column and a numeric difference column.
#'
#' @family compare
#' @seealso [compare_values()].
#' @examples
#' a <- data.frame(feature = c("price", "quality", "service"),
#'                 performance = c(3.1, 4.2, 3.5))
#' b <- data.frame(feature = c("price", "quality", "service"),
#'                 performance = c(2.8, 4.4, 3.9))
#' p <- compare_values(b, a) %>% plot_diff()
#' # p is a ggplot; print(p) to draw it
#' @export
plot_diff <- function(data, label = feature, difference = difference,
                      limits = NULL, digits = 2,
                      pos_colour = "#A7C23D", neg_colour = "#FFCB3E",
                      title = NULL) {
  label_name <- rlang::as_name(rlang::ensym(label))
  diff_name <- rlang::as_name(rlang::ensym(difference))

  d <- tibble::as_tibble(data)
  d <- d[!is.na(d[[diff_name]]), , drop = FALSE]
  d <- d[order(d[[diff_name]], decreasing = TRUE), , drop = FALSE]
  d[[label_name]] <- factor(as.character(d[[label_name]]),
                            levels = rev(unique(as.character(d[[label_name]]))))
  d$.cls <- ifelse(d[[diff_name]] > 0, "pos", "neg")
  d$.lab <- ifelse(d[[diff_name]] > 0,
                   paste0("+", round(d[[diff_name]], digits)),
                   as.character(round(d[[diff_name]], digits)))
  d$.hj <- ifelse(d[[diff_name]] > 0, -0.2, 1.2)

  if (is.null(limits)) {
    m <- max(abs(d[[diff_name]]), na.rm = TRUE)
    if (!is.finite(m) || m == 0) m <- 1
    limits <- c(-m, m) * 1.25
  }

  ggplot2::ggplot(d, ggplot2::aes(.data[[label_name]], .data[[diff_name]],
                                  fill = .data$.cls)) +
    ggplot2::geom_col() +
    ggplot2::geom_text(ggplot2::aes(label = .data$.lab, hjust = .data$.hj)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_y_continuous(limits = limits) +
    ggplot2::scale_fill_manual(values = c(pos = pos_colour, neg = neg_colour)) +
    ggplot2::labs(x = "", y = "", title = title) +
    ggplot2::coord_flip() +
    theme_ezrsurvey(transparent = TRUE)
}
