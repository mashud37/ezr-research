#' Round an axis maximum up to a "nice" value
#'
#' Picks the smallest multiple of `unit` that is greater than or equal to
#' `max(x)`. This reproduces the dynamic y-axis trick used throughout the
#' original survey reports, where bar charts are given a tidy ceiling in units
#' of 25 (percentages) or 5 (NPS counts) so that data labels never collide with
#' the top of the panel.
#'
#' @param x A numeric vector. `NA` values are ignored.
#' @param unit Size of the rounding step (e.g. `25` for percentages, `5` for
#'   smaller counts). Must be a positive number.
#' @param pad Extra headroom added to the result, in the same units as `x`.
#'   Useful to leave space for annotations above the tallest bar. Defaults to
#'   `0`.
#'
#' @return A single numeric value: the padded, rounded-up ceiling. Returns `NA`
#'   if `x` is empty or all `NA`.
#'
#' @details
#' The ceiling is `(floor(max(x) / unit) + 1) * unit + pad`: the *next*
#' multiple of `unit` strictly above `max(x)`, always leaving headroom even
#' when the max already sits exactly on a multiple (e.g. `nice_max(75)` is
#' `100`, not `75`). Use `pad` for additional headroom on top of that, e.g.
#' for annotations above the tallest bar. An all-`NA` logical column (a common
#' shape for an empty survey field) is tolerated and returns `NA`. This is the
#' engine behind [scale_y_pct()] and the percentage plot wrappers, which is
#' why their bars never quite touch the top of the panel.
#'
#' @family scales
#' @seealso [scale_y_pct()], [label_pct()].
#' @examples
#' nice_max(c(12, 63, 40))
#' #> [1] 75
#'
#' nice_max(80, unit = 25)        # already need >75, so jumps to 100
#' #> [1] 100
#'
#' nice_max(75, unit = 25)        # exact multiple still advances, for headroom
#' #> [1] 100
#'
#' nice_max(c(8, 17), unit = 5, pad = 10)   # next multiple of 5 (20) + 10
#' #> [1] 30
#' @export
nice_max <- function(x, unit = 25, pad = 0) {
  if (!is.numeric(x)) {
    # Tolerate an all-NA logical vector (e.g. an empty/blank survey column).
    if (is.logical(x) && all(is.na(x))) {
      x <- as.numeric(x)
    } else {
      stop("`x` must be numeric.", call. = FALSE)
    }
  }
  if (length(unit) != 1L || !is.numeric(unit) || unit <= 0) {
    stop("`unit` must be a single positive number.", call. = FALSE)
  }
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  m <- max(x)
  # Next multiple of `unit` strictly above m, so the tallest bar always has
  # headroom -- an exact multiple still advances one full step.
  steps <- floor(m / unit) + 1
  steps * unit + pad
}

#' Continuous y-scale capped at a nice maximum with optional percent labels
#'
#' A thin wrapper around [ggplot2::scale_y_continuous()] that sets the upper
#' limit with [nice_max()] and, by default, formats the axis as percentages.
#' Designed for the percentage bar charts produced by [calc_percentage()].
#'
#' @param values Numeric vector used to determine the axis ceiling, typically
#'   the column being plotted. If `NULL` (default) the limit is left to
#'   ggplot2 and only the label formatting is applied.
#' @param unit,pad Passed to [nice_max()].
#' @param max Optional fixed upper limit. If supplied (e.g. `100`), it overrides
#'   the dynamic [nice_max()] ceiling. Defaults to `NULL`.
#' @param labels One of:
#'   * `TRUE` (default) -- format breaks as `"42%"`.
#'   * `FALSE` -- hide axis labels entirely (`labels = NULL`).
#'   * a function -- used directly as the `labels` argument.
#' @param ... Further arguments passed to [ggplot2::scale_y_continuous()].
#'
#' @return A ggplot2 scale you can add to a plot with `+`.
#'
#' @details
#' The upper limit is chosen in one of three ways, in order of precedence: a
#' fixed `max` if you supply one; otherwise [nice_max()] of `values`; otherwise
#' left to ggplot2. Labels default to whole-percent strings via [label_pct()].
#' [plot_bars()] calls this for you, reading its `unit` and `max` from the
#' `pct_axis_unit` / `pct_axis_max` options (see [ezrsurvey_options()]), so you
#' rarely add it by hand -- but it is exported for custom charts.
#'
#' @family scales
#' @seealso [nice_max()], [label_pct()], [plot_bars()].
#' @examples
#' df <- calc_percentage(podracing_survey, demo_gender)
#' ggplot(df, aes(demo_gender, pct)) +
#'   geom_col() +
#'   scale_y_pct(df$pct)            # axis capped at a tidy multiple, "%" labels
#' @export
scale_y_pct <- function(values = NULL, unit = 25, pad = 0, max = NULL,
                        labels = TRUE, ...) {
  lab_fun <- if (isTRUE(labels)) {
    label_pct()
  } else if (isFALSE(labels)) {
    NULL
  } else if (is.function(labels)) {
    labels
  } else {
    stop("`labels` must be TRUE, FALSE or a function.", call. = FALSE)
  }

  limits <- NULL
  if (!is.null(max)) {
    limits <- c(0, max)
  } else if (!is.null(values)) {
    limits <- c(0, nice_max(values, unit = unit, pad = pad))
  }

  ggplot2::scale_y_continuous(limits = limits, labels = lab_fun, ...)
}

#' Percent label formatter
#'
#' Returns a function that turns numbers into percent strings, e.g. `42`
#' becomes `"42%"`. The input is assumed to already be on a 0-100 scale (as
#' produced by [calc_percentage()]), not a 0-1 proportion.
#'
#' @param digits Number of decimal places to keep. Defaults to `0`.
#' @param suffix String appended after the number. Defaults to `"%"`.
#'
#' @return A function suitable for the `labels` argument of a ggplot2 scale or
#'   for use with [geom_text()][ggplot2::geom_text].
#'
#' @details
#' `label_pct()` returns a *function* (a closure), not formatted strings -- this
#' is the form ggplot2 scales expect for their `labels` argument. The number is
#' rounded to `digits` decimal places with [formatC()] and `suffix` appended.
#' Because the input is assumed to be on a 0--100 scale, `label_pct()(42)` is
#' `"42%"`, not `"4200%"`.
#'
#' @family scales
#' @seealso [scale_y_pct()].
#' @examples
#' f <- label_pct()
#' f(c(0, 33.4, 100))
#' #> [1] "0%"   "33%"  "100%"
#'
#' label_pct(1)(33.45)
#' #> [1] "33.5%"
#' @export
label_pct <- function(digits = 0, suffix = "%") {
  function(x) {
    paste0(formatC(x, format = "f", digits = digits), suffix)
  }
}
