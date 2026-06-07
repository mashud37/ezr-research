# Internal: coerce a band spec into a tidy data frame with from/to/label/colour.
normalize_bands <- function(bands) {
  bands <- as.data.frame(bands, stringsAsFactors = FALSE)
  if (!all(c("from", "to", "label") %in% names(bands))) {
    stop("`bands` must have columns `from`, `to` and `label`.", call. = FALSE)
  }
  if (is.null(bands$colour)) {
    bands$colour <- if (!is.null(bands$color)) bands$color else "black"
  }
  bands
}

# Internal: best-effort inference of the opposite-axis position for the marker
# line, by building the plot and reading its panel range.
infer_at <- function(plot, axis) {
  opp <- if (axis == "x") "y" else "x"
  built <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) NULL)
  if (is.null(built)) {
    stop("Could not infer `at`; please supply it explicitly.", call. = FALSE)
  }
  pp <- built$layout$panel_params[[1]]
  rng <- pp[[paste0(opp, ".range")]]
  if (is.null(rng)) {
    rng <- range(pp[[opp]]$breaks, na.rm = TRUE)
  }
  max(rng, na.rm = TRUE)
}

#' Annotate a plot with labelled decision bands
#'
#' Programmatically adds the BAD / OK / GOOD style decision markers seen across
#' the original survey charts: for each band a thin coloured marker line runs
#' along one axis, with a bold centred label. This turns the copy-pasted
#' `geom_rect()` + `annotate("text", x = median(seq(from, to, .1)), ...)` blocks
#' into one call, so any chart can be given consistent "where's good, where's
#' bad" guidance.
#'
#' @param plot A ggplot object.
#' @param bands A band specification: a data frame (or one of [bands_rating_3()],
#'   [bands_rating_5()], [bands_nps()]) with columns `from`, `to`, `label` and
#'   optionally `colour`.
#' @param axis Which axis the bands run along: `"x"` (default) or `"y"`.
#' @param at Position on the *opposite* axis at which to draw the marker line and
#'   labels (e.g. the top of a bar chart). If `NULL`, inferred from the plot's
#'   panel range.
#' @param label_offset Distance to nudge labels away from the marker line, in
#'   data units of the opposite axis. Defaults to `0`.
#' @param labels Whether to draw the band labels. Defaults to `TRUE`.
#' @param text_colour,text_size Label appearance. `text_colour = NULL` (default)
#'   uses each band's own colour.
#' @param linewidth Marker line width. Defaults to `1`.
#'
#' @return The plot with the band layers added.
#'
#' @details
#' Bands turn a chart into a decision aid: a thin coloured marker line runs along
#' one axis for each band, with a bold centred label, so a reader instantly sees
#' where "good" and "bad" lie. Supply a band spec (a data frame with `from`,
#' `to`, `label` and optional `colour`, or one of the [bands_rating_3()]
#' presets), the `axis` the bands run along, and `at` -- the position on the
#' opposite axis for the marker line (usually the top of the panel; inferred from
#' the plot when omitted).
#'
#' @family decisions
#' @seealso [mark_value()] to add a single "you are here" marker.
#'
#' @examples
#' \dontrun{
#' plot_ipm_base |>
#'   annotate_bands(bands_rating_3(), axis = "x", at = 30)
#' }
#' @export
annotate_bands <- function(plot, bands, axis = c("x", "y"), at = NULL,
                           label_offset = 0, labels = TRUE,
                           text_colour = NULL, text_size = 4, linewidth = 1) {
  axis <- match.arg(axis)
  bands <- normalize_bands(bands)
  if (is.null(at)) {
    at <- infer_at(plot, axis)
  }

  layers <- list()
  for (i in seq_len(nrow(bands))) {
    from <- bands$from[i]
    to <- bands$to[i]
    col <- bands$colour[i]
    centre <- (from + to) / 2
    lab_col <- text_colour %||% col

    if (axis == "x") {
      layers <- c(layers, list(
        ggplot2::annotate("rect", xmin = from, xmax = to,
                          ymin = at, ymax = at, fill = NA,
                          colour = col, linewidth = linewidth)
      ))
      if (labels) {
        layers <- c(layers, list(
          ggplot2::annotate("text", x = centre, y = at - label_offset,
                            label = bands$label[i], colour = lab_col,
                            size = text_size, fontface = "bold")
        ))
      }
    } else {
      layers <- c(layers, list(
        ggplot2::annotate("rect", ymin = from, ymax = to,
                          xmin = at, xmax = at, fill = NA,
                          colour = col, linewidth = linewidth)
      ))
      if (labels) {
        layers <- c(layers, list(
          ggplot2::annotate("text", y = centre, x = at - label_offset,
                            label = bands$label[i], colour = lab_col,
                            size = text_size, fontface = "bold")
        ))
      }
    }
  }
  plot + layers
}

#' Mark a single value on a plot
#'
#' Adds a reference line (and optional label) at a single value -- the "you are
#' here" marker used on the NPS and quality gauges.
#'
#' @param plot A ggplot object.
#' @param value Numeric position of the marker.
#' @param axis Axis the value is on: `"x"` (default, draws a vertical line) or
#'   `"y"` (horizontal line).
#' @param colour,linewidth Line appearance.
#' @param label Optional text label drawn at the marker.
#' @param ... Passed to [ggplot2::annotate()] for the label.
#'
#' @return The plot with the marker added.
#' @family decisions
#'
#' @examples
#' \dontrun{
#' p |> mark_value(42, axis = "x", label = "NPS 42")
#' }
#' @export
mark_value <- function(plot, value, axis = c("x", "y"),
                       colour = "black", linewidth = 1, label = NULL, ...) {
  axis <- match.arg(axis)
  line <- if (axis == "x") {
    ggplot2::geom_vline(xintercept = value, colour = colour, linewidth = linewidth)
  } else {
    ggplot2::geom_hline(yintercept = value, colour = colour, linewidth = linewidth)
  }
  out <- plot + line
  if (!is.null(label)) {
    out <- out + ggplot2::annotate(
      "text",
      x = if (axis == "x") value else Inf,
      y = if (axis == "x") Inf else value,
      label = label, fontface = "bold", ...
    )
  }
  out
}

#' Built-in decision-band presets
#'
#' Ready-made band specifications for [annotate_bands()].
#'
#' * `bands_rating_3()` -- BAD / OK / GOOD over a 1-5 rating axis.
#' * `bands_rating_5()` -- per-point labels (1 Very bad .. 5 Very good) over 1-5.
#' * `bands_nps()` -- Detractor / Passive / Promoter over a 0-10 axis.
#'
#' @return A [tibble][tibble::tibble] with `from`, `to`, `label` and `colour`.
#' @family decisions
#'
#' @examples
#' bands_rating_3()
#' bands_nps()
#' @rdname band_presets
#' @export
bands_rating_3 <- function() {
  tibble::tibble(
    label = c("BAD", "OK", "GOOD"),
    from = c(1, 3, 4),
    to = c(3, 4, 5),
    colour = c("#FF3300", "#FFCB3E", "#86A33B")
  )
}

#' @rdname band_presets
#' @export
bands_rating_5 <- function() {
  tibble::tibble(
    label = c("1\nVery bad", "2", "3\nOk", "4", "5\nVery good"),
    from = c(0.5, 1.5, 2.5, 3.5, 4.5),
    to = c(1.5, 2.5, 3.5, 4.5, 5.5),
    colour = unname(pal_rating5)
  )
}

#' @rdname band_presets
#' @export
bands_nps <- function() {
  tibble::tibble(
    label = c("DETRACTOR", "PASSIVE", "PROMOTER"),
    from = c(-0.5, 6.5, 8.5),
    to = c(6.5, 8.5, 10.5),
    colour = unname(pal_nps)
  )
}
