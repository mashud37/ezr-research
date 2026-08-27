# Internal: the geom_col() width that keeps bar thickness constant across
# charts. `width` is a fraction of one category slot, and a slot shrinks as
# categories multiply -- so a fixed 0.66 draws a 3-bar chart's bars more than
# twice as thick as an 8-bar chart's, which is what makes a deck look incoherent
# when you flick through it. Scaling the fraction with the bar count cancels
# that out: thickness is bar_width / bar_ref_items either way. Past the point
# where a bar would fill its slot the fraction is capped and bars do get thinner,
# which is unavoidable once a chart is that dense.
consistent_bar_width <- function(n_items) {
  base <- ezrsurvey_default("bar_width") %||% 0.66
  ref <- ezrsurvey_default("bar_ref_items") %||% 6
  if (!is.finite(n_items) || n_items < 1L || !is.finite(ref) || ref < 1) {
    return(base)
  }
  min(0.9, base * n_items / ref)
}

# Internal: choose orientation, wrap width, label size and sort direction for
# plot_bars(). `orientation` and `sort` may be "auto" (decided here from the
# number of bars and the longest label) or an explicit choice (passed through).
auto_bar_layout <- function(labels, n_items, orientation, is_ordinal, sort,
                            wrap, label_size) {
  max_label <- if (length(labels)) max(nchar(labels), na.rm = TRUE) else 0L

  if (orientation == "auto") {
    use_bars <- n_items > ezrsurvey_default("bar_cols_max_items") ||
      max_label > ezrsurvey_default("bar_cols_max_label")
    orientation <- if (use_bars) "bars" else "cols"
  }

  if (is.null(wrap)) {
    wrap <- if (orientation == "bars") ezrsurvey_default("bar_wrap_bars") else
      ezrsurvey_default("bar_wrap_cols")
  }

  if (sort == "auto") {
    # An intentional ordinal scale is left as-is; otherwise put the longest bar
    # on top (bars, after coord_flip => ascending) or on the left (cols).
    sort <- if (is_ordinal) "none" else if (orientation == "bars") "asc" else "desc"
  }

  if (is.null(label_size)) {
    thr <- ezrsurvey_default("bar_cols_max_items")
    label_size <- max(
      ezrsurvey_default("bar_size_min"),
      ezrsurvey_default("bar_label_size") -
        ezrsurvey_default("bar_size_step") * max(0, n_items - thr)
    )
  }

  list(orientation = orientation, wrap = wrap, sort = sort, size = label_size)
}

#' Bar chart of a percentage table (auto-laid-out)
#'
#' Plots the output of [calc_percentage()] (or [calc_percentage_multi()]) as a
#' labelled bar chart, with a tidy auto-scaled axis ([nice_max()]) and the
#' ezrsurvey theme. By default the **layout is chosen for you**: vertical columns
#' for a few short labels, horizontal bars for many or long ones, with long
#' labels wrapped, the text size stepped down as bars multiply, and the bars
#' ordered so the longest sits at the top (bars) or on the left (cols).
#' Generalises the `bars_freq()` helper from the original reports.
#'
#' @param data A data frame with a category column and a value column.
#' @param label Category column (unquoted). If `NULL` (default), the first
#'   non-`n`, non-value column is used.
#' @param value Value column (unquoted). Defaults to `pct`.
#' @param orientation `"auto"` (default), `"cols"` (vertical) or `"bars"`
#'   (horizontal). `"auto"` picks horizontal bars when there are more than
#'   `bar_cols_max_items` items or a label longer than `bar_cols_max_label`
#'   characters (see [ezrsurvey_options()]).
#' @param sort `"auto"` (default), `"none"`, `"asc"` or `"desc"`. `"auto"` orders
#'   bars by value so the longest is on top (bars) or on the left (cols), but
#'   leaves an intentional ordinal scale (an ordered factor, e.g. from a
#'   registered order) untouched.
#' @param wrap Label wrap width in characters ([stringr::str_wrap()]). `NULL`
#'   (default) uses `bar_wrap_cols` / `bar_wrap_bars` for the chosen orientation.
#' @param flip Deprecated back-compat shortcut: `TRUE` forces `orientation =
#'   "bars"`, `FALSE` forces `"cols"`. `NULL` (default) defers to `orientation`.
#' @param avg_line If `TRUE`, add a reference line at the mean value. Defaults to
#'   `FALSE`.
#' @param axis_labels If `TRUE`, show the percentage axis; if `FALSE` (default)
#'   hide it (the bars carry their own data labels).
#' @param unit Axis rounding step passed to [nice_max()]. Defaults to the
#'   `pct_axis_unit` option (`25`; see [ezrsurvey_options()]).
#' @param max Optional fixed y-axis maximum (e.g. `100`). Defaults to the
#'   `pct_axis_max` option (`NULL` = dynamic).
#' @param fill Bar fill colour. `NULL` (default) uses the brand primary colour
#'   when a brand is set (see [use_brand()]), else [pal_neutral].
#' @param title Optional plot title.
#' @param label_size Data-label text size. `NULL` (default) steps down from
#'   `bar_label_size` as the number of bars grows (floored at `bar_size_min`).
#'
#' @return A ggplot object.
#'
#' @details
#' Expects a summary table (from [calc_percentage()] and friends), not raw survey
#' rows. The label column is auto-detected as the first non-`n`, non-value column,
#' so a piped percentage table just works. The layout decisions all read from the
#' `bar_*` options ([ezrsurvey_options()]): `orientation = "auto"` switches to
#' horizontal bars once there are many or long labels, labels are wrapped to
#' `bar_wrap_cols` / `bar_wrap_bars`, the data-label size steps down with the
#' bar count, and `sort = "auto"` puts the longest bar at the top (bars) or on the
#' left (cols) -- unless the label column is an ordered factor (a registered or
#' explicit order), which is preserved. The axis ceiling is chosen by [nice_max()]
#' / the `pct_axis_*` options so data labels never collide with the panel top, and
#' the `%` axis is hidden unless `axis_labels = TRUE`. Add decision guidance with
#' [annotate_bands()].
#'
#' Bars are drawn to a constant thickness regardless of how many there are
#' (`bar_width` / `bar_ref_items`, see [ezrsurvey_options()]), so a three-answer
#' chart and a ten-answer chart look like they belong in the same deck instead
#' of the first one's bars turning into slabs.
#'
#' @family plots
#' @seealso [calc_percentage()], [scale_y_pct()], [annotate_bands()].
#' @examples
#' # auto layout: few short labels -> vertical columns, largest on the left
#' p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
#'
#' # many long labels -> horizontal bars, wrapped, largest on top
#' p2 <- calc_percentage(podracing_survey, fav_driver) %>% plot_bars()
#'
#' # an ordinal scale keeps its order; force horizontal with orientation
#' p3 <- calc_percentage(podracing_survey, demo_edu) %>%
#'   plot_bars(orientation = "bars")
#' @export
plot_bars <- function(data, label = NULL, value = pct,
                      orientation = c("auto", "cols", "bars"),
                      sort = c("auto", "none", "asc", "desc"),
                      wrap = NULL, flip = NULL,
                      avg_line = FALSE, axis_labels = FALSE,
                      unit = ezrsurvey_default("pct_axis_unit"),
                      max = ezrsurvey_default("pct_axis_max"),
                      fill = NULL, title = NULL, label_size = NULL) {
  fill <- fill %||% ezrsurvey_default("brand_color_primary") %||%
    ezrsurvey_default("brand_colors")[1] %||% pal_neutral
  orientation <- match.arg(orientation)
  sort <- match.arg(sort)
  if (!is.null(flip)) orientation <- if (isTRUE(flip)) "bars" else "cols"

  value_sym <- rlang::ensym(value)
  value_name <- rlang::as_name(value_sym)
  label_q <- rlang::enquo(label)
  if (rlang::quo_is_null(label_q)) {
    cand <- setdiff(names(data), c("n", value_name))
    if (length(cand) == 0L) {
      stop("Could not auto-detect a label column; pass `label`.", call. = FALSE)
    }
    label_sym <- rlang::sym(cand[1])
  } else {
    label_sym <- rlang::ensym(label)
  }
  label_name <- rlang::as_name(label_sym)

  vals <- data[[value_name]]
  n_items <- nrow(data)
  is_ordinal <- is.ordered(data[[label_name]])
  layout <- auto_bar_layout(as.character(data[[label_name]]), n_items,
                            orientation, is_ordinal, sort, wrap, label_size)

  # Order rows by value (unless the label is an intentional ordinal scale).
  if (layout$sort != "none") {
    o <- order(vals, decreasing = (layout$sort == "desc"))
    data <- data[o, , drop = FALSE]
    vals <- vals[o]
    lev_order <- unique(as.character(data[[label_name]]))
  } else if (is.factor(data[[label_name]])) {
    lev_order <- levels(data[[label_name]])
  } else {
    lev_order <- unique(as.character(data[[label_name]]))
  }

  # Wrap labels and lock the level order to the chosen ordering.
  data[[label_name]] <- factor(
    stringr::str_wrap(as.character(data[[label_name]]), width = layout$wrap),
    levels = unique(stringr::str_wrap(lev_order, width = layout$wrap))
  )
  data[[".bar_label"]] <- label_pct()(vals)

  pad <- if (layout$orientation == "bars") unit * 0.5 else 0
  axis_sz <- max(6, 11 - 0.6 * max(0, n_items - ezrsurvey_default("bar_cols_max_items")))
  cat_axis_theme <- if (layout$orientation == "bars") {
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = axis_sz))
  } else {
    ggplot2::theme(axis.text.x = ggplot2::element_text(size = axis_sz))
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(!!label_sym, !!value_sym)) +
    ggplot2::geom_col(ggplot2::aes(fill = ""), width = consistent_bar_width(n_items)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::labs(x = "", y = "", title = title) +
    scale_y_pct(values = vals, unit = unit, pad = pad, max = max,
                labels = axis_labels) +
    ggplot2::scale_fill_manual(values = fill) +
    theme_ezrsurvey(transparent = TRUE) +
    cat_axis_theme

  if (layout$orientation == "bars") {
    p <- p +
      ggplot2::geom_text(ggplot2::aes(label = .data$.bar_label), hjust = -0.3,
                         size = layout$size) +
      ggplot2::coord_flip()
  } else {
    p <- p +
      ggplot2::geom_text(ggplot2::aes(label = .data$.bar_label), vjust = -1,
                         size = layout$size)
  }

  if (avg_line) {
    p <- p + ggplot2::geom_hline(yintercept = mean(vals, na.rm = TRUE))
  }
  p
}

#' Stacked rating bars with weighted-average ordering
#'
#' Draws a 100%-stacked bar per feature across an ordinal rating scale, labels
#' each segment, and orders features by their weighted mean rating -- the
#' likeability / purchase / feature-rating charts from the original reports.
#'
#' @param data Long data with one row per feature x rating level.
#' @param feature Feature column (unquoted).
#' @param level Ordered rating-level column (unquoted), e.g. a factor like
#'   `"1 - Very bad"` .. `"5 - Very good"`. The leading digit is used as the
#'   numeric weight.
#' @param value Percentage column (unquoted). Defaults to `pct`.
#' @param palette Fill colours, named by the level labels. Defaults to `NULL`,
#'   which derives a red -> amber -> green rating palette from the level labels
#'   themselves (mapping each by its leading digit), so a very-bad..very-good
#'   scale is coloured worse-to-better automatically. Pass a named vector to
#'   override.
#' @param label_min Hide segment labels below this percentage. Defaults to `1`.
#' @param show_average Append the weighted mean to each feature label. Defaults
#'   to `TRUE`.
#'
#' @return A ggplot object.
#'
#' @details
#' Each feature becomes a 100%-stacked bar across the rating scale, and features
#' are ordered by their weighted-mean rating (the leading digit of each `level`
#' is the weight), so the best-rated feature sits at the top. The weighted mean
#' is appended to each feature label when `show_average = TRUE`. Feed it a long
#' table with one row per feature x rating level; the `partner_*` likeability and
#' purchase questions in the source reports are the canonical use.
#'
#' @family plots
#' @seealso [calc_percentage()], [scale_fill_rating()].
#' @examples
#' rating_long <- podracing_survey %>%
#'   select(starts_with("ratings_")) %>%
#'   tidyr::pivot_longer(everything(),
#'                       names_to = "feature", values_to = "level") %>%
#'   filter(level != "") %>%
#'   mutate(level = paste0(recode_likert(level), " - ", level)) %>%
#'   count(feature, level) %>%
#'   group_by(feature) %>%
#'   mutate(pct = n / sum(n) * 100) %>%
#'   ungroup()
#' p <- plot_stacked_rating(rating_long, feature, level)
#' @export
#' @export
plot_stacked_rating <- function(data, feature, level, value = pct,
                                palette = NULL, label_min = 1,
                                show_average = TRUE) {
  feature_sym <- rlang::ensym(feature)
  level_sym <- rlang::ensym(level)
  value_sym <- rlang::ensym(value)
  feature_name <- rlang::as_name(feature_sym)
  level_name <- rlang::as_name(level_sym)
  value_name <- rlang::as_name(value_sym)

  d <- tibble::as_tibble(data)
  d[[".num"]] <- as.integer(stringr::str_extract(as.character(d[[level_name]]),
                                                 "[1-9]"))

  avg_tbl <- d %>%
    dplyr::group_by(.data[[feature_name]]) %>%
    dplyr::summarise(avg = sum(.data$.num * .data[[value_name]] / 100,
                               na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(.data$avg))

  avg_tbl[[".flabel"]] <- if (show_average) {
    paste0(avg_tbl[[feature_name]], " - ", sprintf("%.2f", round(avg_tbl$avg, 2)))
  } else {
    as.character(avg_tbl[[feature_name]])
  }
  avg_tbl[[".flabel"]] <- factor(avg_tbl[[".flabel"]],
                                 levels = rev(unique(avg_tbl[[".flabel"]])))

  d <- dplyr::left_join(d, avg_tbl[, c(feature_name, ".flabel")],
                        by = feature_name)
  d[[".seg_label"]] <- ifelse(round(d[[value_name]]) > label_min,
                              paste0(round(d[[value_name]]), "%"), "")

  pal <- palette
  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(.data$.flabel, !!value_sym, fill = !!level_sym)
  ) +
    ggplot2::geom_col() +
    ggplot2::geom_text(ggplot2::aes(label = .data$.seg_label),
                       position = ggplot2::position_stack(vjust = .5)) +
    ggplot2::scale_y_continuous(labels = label_pct()) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = "", y = "") +
    ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE)) +
    theme_ezrsurvey(transparent = TRUE) +
    ggplot2::theme(legend.position = "top",
                   legend.title = ggplot2::element_blank())

  if (is.null(pal)) {
    pal <- rating_palette(d[[level_name]])
  }
  p <- p + ggplot2::scale_fill_manual(values = pal)
  p
}

#' A stacked rating chart for a whole block of questions
#'
#' The one-line form of [plot_stacked_rating()] for the common case: a block of
#' columns sharing a prefix, each asking the same rating question about a
#' different feature or brand. Tabulates the block, tidies the question names,
#' numbers the answers by their position on the scale and stacks the result.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()]).
#' @param prefix The block's shared column prefix, e.g. `"ratings_"`. It is
#'   stripped from the feature labels.
#' @param levels The scale's answer wordings, worst first. `NULL` (default)
#'   looks the block up in the order registry ([register_order()]), falling back
#'   to the [recode_likert()] default five-point scale.
#' @param digits Decimal places kept in the underlying percentages. Default `2`.
#' @param ... Passed to [plot_stacked_rating()] (`palette`, `label_min`,
#'   `show_average`).
#'
#' @return A ggplot object.
#'
#' @details
#' Answers are numbered by their position in `levels`, which is what orders the
#' features by their weighted mean and colours the segments worst-to-best. A
#' wording that is not on the scale cannot be numbered, so it is reported rather
#' than being silently dropped into an unlabelled segment: check it against the
#' raw export, since exports often differ from a questionnaire by a typo.
#' Registering the block once with
#' `register_order("likeability", levels, prefixes = "partner_likeability_")`
#' removes the `levels` argument from every later call.
#'
#' @family plots
#' @seealso [plot_stacked_rating()], [calc_percentage_batch()],
#'   [register_order()].
#' @examples
#' plot_rating_grid(podracing_survey, "ratings_")
#'
#' plot_rating_grid(podracing_survey, "partner_likeability_",
#'                  levels = c("Very unlikeable", "Unlikeable",
#'                             "Likeable", "Very likeable"))
#' @export
plot_rating_grid <- function(data = NULL, prefix, levels = NULL, digits = 2,
                             ...) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(prefix)),
                            missing(prefix))
  data <- r$data
  prefix <- rlang::eval_tidy(r$cols[[1]])

  cols <- names(data)[startsWith(names(data), prefix)]
  if (length(cols) == 0L) {
    stop("No columns start with '", prefix, "'.", call. = FALSE)
  }
  if (is.null(levels)) {
    levels <- order_for(cols[[1]]) %||%
      c("Very bad", "Bad", "Ok", "Good", "Very good")
  }

  tab <- calc_percentage_batch(data, dplyr::all_of(cols), digits = digits,
                               prefix = prefix)
  ranks <- recode_likert(tab$answer, levels = levels)
  unknown <- unique(tab$answer[is.na(ranks)])
  if (length(unknown)) {
    message("plot_rating_grid: ", length(unknown),
            " answer(s) are not on the '", prefix, "' scale and cannot be ",
            "ranked: ", paste(unknown, collapse = ", "),
            ". Check `levels` against the data.")
  }
  tab$answer <- paste(ranks, "-", tab$answer)
  plot_stacked_rating(tab, variable, answer, ...)
}

#' Score gauge with decision bands and a value marker
#'
#' A horizontal gauge that places a single score (NPS or mean rating) onto a
#' banded scale, with a "you are here" marker. Generalises the NPS and quality
#' gauges from the original summary slide.
#'
#' @param score The score to mark (NPS on -100..100, or a mean rating on 1..5).
#' @param scale `"nps"` (default) or `"rating"`, selecting the band layout and
#'   limits.
#' @param title Optional title; a sensible default is generated from `score`.
#' @param height Bar thickness in plot units. Defaults to `0.5`.
#' @param label_size Band-label text size. `NULL` (default) matches the theme's
#'   base font size (11 pt).
#'
#' @return A ggplot object.
#'
#' @details
#' Takes a single number (not a dataset) and places it on a coloured band scale
#' with a black marker, for the headline "where do we stand" slide. `"nps"` uses
#' a -100..100 scale banded from needs-work to excellent; `"rating"` uses a 1..5
#' scale with BAD/OK/GOOD bands. Pair it with [calc_nps()] for the score.
#'
#' @family plots
#' @seealso [calc_nps()], [plot_nps()].
#' @examples
#' nps <- calc_nps(podracing_survey, nps_value)$nps
#' p <- plot_nps_gauge(nps)
#' p_rating <- plot_nps_gauge(3.8, scale = "rating")
#' @export
plot_nps_gauge <- function(score, scale = c("nps", "rating"),
                           title = NULL, height = 0.5, label_size = NULL) {
  scale <- match.arg(scale)
  label_size <- label_size %||% (11 / ggplot2::.pt)
  if (scale == "nps") {
    bands <- bands_nps_score()
    lim <- c(-100, 100)
    if (is.null(title)) title <- paste0("Net Promoter Score of: ", round(score))
  } else {
    bands <- bands_rating_3()
    lim <- c(1, 5)
    if (is.null(title)) {
      title <- paste0("Quality rating of: ", round(score, 2))
    }
  }

  p <- ggplot2::ggplot(bands) +
    ggplot2::geom_rect(ggplot2::aes(xmin = .data$from, xmax = .data$to,
                                    ymin = 0, ymax = height,
                                    fill = .data$label)) +
    ggplot2::geom_text(ggplot2::aes(x = (.data$from + .data$to) / 2,
                                    y = height / 2, label = .data$label),
                       colour = "white", fontface = "bold",
                       size = label_size) +
    ggplot2::geom_segment(
      data = data.frame(score = score),
      ggplot2::aes(x = .data$score, xend = .data$score, y = 0, yend = height),
      colour = "black", linewidth = 1.2, inherit.aes = FALSE
    ) +
    ggplot2::scale_fill_manual(values = stats::setNames(bands$colour, bands$label)) +
    ggplot2::scale_x_continuous(limits = lim) +
    ggplot2::scale_y_continuous(limits = c(0, height)) +
    ggplot2::labs(title = title, x = "", y = "") +
    theme_ezrsurvey(transparent = TRUE) +
    ggplot2::theme(axis.text.y = ggplot2::element_blank())
  p
}

# Internal: band layout, axis limits and score formatter for one gauge scale.
gauge_scale <- function(scale) {
  if (scale == "nps") {
    list(
      bands = bands_nps_score(),
      lo = -100, hi = 100,
      fmt = function(s) sprintf("%+d", as.integer(round(s)))
    )
  } else {
    list(bands = bands_rating_3(), lo = 1, hi = 5,
         fmt = function(s) sprintf("%.2f / 5", s))
  }
}

# Internal: guess a gauge scale from a score's range (an NPS spans well past the
# 1-5 rating range). Used only when `scales` is not supplied.
infer_gauge_scale <- function(score) {
  if (!is.finite(score) || score < 1 || score > 5) "nps" else "rating"
}

#' Stacked score gauges (NPS over average quality, etc.)
#'
#' Draws two or more scores as thin banded gauge bars stacked one above another,
#' each on its own scale with a "you are here" marker. The headline summary
#' slide: the Net Promoter Score on top and the average feature quality rating
#' below it, so both key numbers sit together instead of one fat bar filling the
#' slide.
#'
#' @param scores A **named** numeric vector; each name labels a gauge and each
#'   value is placed on its scale. The first is drawn at the top.
#' @param scales Which band scale each gauge uses: `"nps"` (a -100..100 Net
#'   Promoter scale) or `"rating"` (a 1..5 quality scale). Length 1 (recycled)
#'   or one per score. `NULL` (default) infers `"rating"` for a value in 1..5
#'   and `"nps"` otherwise.
#' @param title Optional title. `NULL` (default) draws none, so a slide title can
#'   carry the wording instead.
#' @param height Bar thickness in plot units (row spacing is 1). Defaults to
#'   `0.5`, keeping each bar deliberately thin so several share the panel.
#' @param label_size Band-label text size. `NULL` (default) is a compact
#'   `10 / .pt`.
#'
#' @return A ggplot object.
#'
#' @details
#' Each gauge is normalised to its own scale, so an NPS of `+23` and a quality
#' rating of `3.4` line up on a shared 0..1 panel with the band boundaries drawn
#' where each scale puts them (the NPS gauge reuses the [plot_nps_gauge()] bands;
#' the rating gauge uses [bands_rating_3()]). The score for each gauge is printed
#' beside its label, and a black marker shows where it lands. Because the bars
#' are thin and stacked, this is the summary-slide companion to the detailed
#' [plot_nps()] distribution and the [plot_ipm()] driver matrix.
#'
#' @family plots
#' @seealso [plot_nps_gauge()], [calc_nps()], [ipm_model()].
#' @examples
#' nps <- calc_nps(podracing_survey, nps_value)$nps
#' quality <- 3.4
#' p <- plot_gauges(c("Net Promoter Score" = nps,
#'                    "Average quality rating" = quality))
#' @export
plot_gauges <- function(scores, scales = NULL, title = NULL, height = 0.5,
                        label_size = NULL) {
  if (!is.numeric(scores) || is.null(names(scores)) ||
      any(!nzchar(names(scores)))) {
    stop("`scores` must be a named numeric vector; the names label the gauges.",
         call. = FALSE)
  }
  n <- length(scores)
  scales <- if (is.null(scales)) {
    vapply(unname(scores), infer_gauge_scale, character(1))
  } else {
    rep_len(scales, n)
  }
  label_size <- label_size %||% (10 / ggplot2::.pt)
  norm <- function(v, lo, hi) (v - lo) / (hi - lo)

  rects <- vector("list", n)
  markers <- vector("list", n)
  ybreaks <- numeric(n)
  ylabels <- character(n)
  for (i in seq_len(n)) {
    yc <- n - i + 1                         # first gauge on top
    sc <- gauge_scale(scales[[i]])
    b <- sc$bands
    xmin <- pmax(0, norm(b$from, sc$lo, sc$hi))
    xmax <- pmin(1, norm(b$to, sc$lo, sc$hi))
    rects[[i]] <- data.frame(
      xmin = xmin, xmax = xmax, xmid = (xmin + xmax) / 2,
      ymin = yc - height / 2, ymax = yc + height / 2,
      colour = b$colour, label = b$label,
      wide = (xmax - xmin) > 0.14,
      stringsAsFactors = FALSE
    )
    mx <- min(1, max(0, norm(scores[[i]], sc$lo, sc$hi)))
    markers[[i]] <- data.frame(x = mx,
                               ymin = yc - height / 2 - 0.06,
                               ymax = yc + height / 2 + 0.06)
    ybreaks[i] <- yc
    ylabels[i] <- paste0(names(scores)[i], "\n", sc$fmt(scores[[i]]))
  }
  rects <- do.call(rbind, rects)
  markers <- do.call(rbind, markers)

  ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = rects,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax,
                   ymin = .data$ymin, ymax = .data$ymax, fill = .data$colour)
    ) +
    ggplot2::geom_text(
      data = rects[rects$wide, , drop = FALSE],
      ggplot2::aes(x = .data$xmid, y = (.data$ymin + .data$ymax) / 2,
                   label = .data$label),
      colour = "white", fontface = "bold", size = label_size
    ) +
    ggplot2::geom_segment(
      data = markers,
      ggplot2::aes(x = .data$x, xend = .data$x, y = .data$ymin,
                   yend = .data$ymax),
      colour = "black", linewidth = 1.2
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(breaks = ybreaks, labels = ylabels,
                                limits = c(min(ybreaks) - height,
                                           max(ybreaks) + height)) +
    ggplot2::labs(title = title, x = "", y = "") +
    theme_ezrsurvey(transparent = TRUE) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(face = "bold", hjust = 1),
      panel.grid = ggplot2::element_blank()
    )
}

#' NPS distribution slide (0-10 scale with group labels)
#'
#' The canonical Net Promoter Score chart: the full 0-10 recommendation
#' distribution as labelled bars coloured by NPS group, with the detractor /
#' passive / promoter shares called out in coloured boxes across the top and the
#' overall NPS in the title. Reproduces the NPS slide from the original report.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param value The 0-10 recommendation column (unquoted). Text such as
#'   `"8 - likely"` is salvaged with [ensure_numeric()].
#' @param title Optional title; defaults to `"Net Promoter Score of: <score>"`.
#'
#' @return A ggplot object.
#'
#' @details
#' Unlike [plot_nps_gauge()] (which takes a single score), this reads the raw
#' 0--10 column and draws the full distribution: one labelled bar per score,
#' coloured red/amber/green by NPS group, with the detractor/passive/promoter
#' shares called out across the top and the overall score in the title. It is the
#' detailed companion slide to the gauge.
#'
#' @family plots
#' @seealso [calc_nps()], [plot_nps_gauge()].
#' @examples
#' p <- plot_nps(podracing_survey, nps_value)
#' # p is a ggplot; print(p) to draw it
#' @export
plot_nps <- function(data = NULL, value, title = NULL) {
  r <- resolve_data_columns(rlang::enquo(data), list(rlang::enquo(value)),
                            missing(value))
  data <- r$data
  col_name <- col_label(r$cols[[1]])
  v <- ensure_numeric(data[[col_name]], quiet = TRUE)
  v <- v[!is.na(v) & v >= 0 & v <= 10]
  if (length(v) == 0L) {
    stop("No valid 0-10 values in '", col_name, "'.", call. = FALSE)
  }

  total <- length(v)
  tab <- tibble::tibble(nps_value = 0:10)
  tab$n <- as.integer(table(factor(round(v), levels = 0:10)))
  tab$pct <- round(tab$n / total * 100)
  tab$group <- nps_group(tab$nps_value)

  score <- round(mean(nps_group(v), na.rm = TRUE) * 100)
  grp <- tapply(tab$pct, tab$group, sum)
  share <- function(g) if (is.na(grp[as.character(g)])) 0 else grp[[as.character(g)]]
  ymax <- nice_max(tab$pct, unit = 5) + 12
  if (is.null(title)) title <- paste0("Net Promoter Score of: ", score)

  ggplot2::ggplot(tab, ggplot2::aes(factor(.data$nps_value), .data$pct,
                                    fill = factor(.data$group))) +
    ggplot2::geom_col(width = consistent_bar_width(nrow(tab))) +
    ggplot2::geom_text(ggplot2::aes(label = paste0(.data$pct, "%")), vjust = -1) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::annotate("text", x = 4, y = ymax,
                      label = paste0(share(-1), "% DETRACTOR\nNot likely"),
                      colour = pal_nps[["-1"]], fontface = "bold",
                      size = 10 / ggplot2::.pt, vjust = 1, lineheight = 0.9) +
    ggplot2::annotate("text", x = 8.5, y = ymax,
                      label = paste0(share(0), "% PASSIVE\nSomewhat likely"),
                      colour = pal_nps[["0"]], fontface = "bold",
                      size = 10 / ggplot2::.pt, vjust = 1, lineheight = 0.9) +
    ggplot2::annotate("text", x = Inf, y = ymax,
                      label = paste0(share(1), "% PROMOTER\nVery likely"),
                      colour = pal_nps[["1"]], fontface = "bold",
                      size = 10 / ggplot2::.pt, vjust = 1, hjust = 1,
                      lineheight = 0.9) +
    ggplot2::scale_y_continuous(limits = c(0, ymax), labels = NULL) +
    scale_fill_nps() +
    ggplot2::labs(title = title, x = "", y = "") +
    theme_ezrsurvey_y(transparent = TRUE)
}

#' Importance / performance matrix
#'
#' Plots an [ipm_model()] table as a scatter of feature performance (x) vs.
#' importance (y), coloured by performance band, with decision bands across the
#' top. Reproduces the IPM slide from the original report.
#'
#' @param model An [ipm_model()] output (`feature`, `importance`, `performance`,
#'   `perf_class`).
#' @param title Optional title; defaults to the average performance.
#' @param repel Use `ggrepel` for non-overlapping labels when available.
#'   Defaults to `TRUE`.
#' @param bands Decision-band spec drawn across the top and used to colour the
#'   points. Defaults to [bands_rating_3()] (BAD 1-3, OK 3-4, GOOD 4-5).
#'
#' @return A ggplot object.
#'
#' @details
#' Each feature is a point: performance on the x-axis (mean 1--5 rating, with a
#' reference line at the average) and importance on the y-axis (relative weight,
#' as a percentage). Each point takes the colour of the decision band it falls
#' in, so a feature averaging 2.4 is red because it sits in the BAD band -- the
#' point and the band behind it can never disagree. Read it by quadrant --
#' high-importance, low-performance features (upper left) are the priorities to
#' fix, while high-importance, high-performance features (upper right) are
#' strengths to protect. Feed it an [ipm_model()] table; uses `ggrepel` for
#' non-overlapping labels when available.
#'
#' @family plots
#' @seealso [ipm_model()], [compare_values()].
#' @examplesIf requireNamespace("rwa", quietly = TRUE)
#' ipm_model(podracing_survey, nps_value, "ratings_") %>% plot_ipm()
#' @export
plot_ipm <- function(model, title = NULL, repel = TRUE,
                     bands = bands_rating_3()) {
  ymax <- nice_max(model$importance + 1, unit = 5)
  avg <- round(mean(model$performance, na.rm = TRUE), 2)
  if (is.null(title)) {
    title <- paste0("Average performance of: ", avg,
                    " (", tolower(band_label(avg, bands)), ")")
  }

  # Colour each point by the band it sits in, so a feature inside the red BAD
  # zone is red -- reading the class off a rounded 1-5 code instead put a 2.4
  # in the amber bucket while the band behind it said BAD.
  model[[".band"]] <- band_colour(model$performance, bands)

  p <- ggplot2::ggplot(model, ggplot2::aes(.data$performance, .data$importance)) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$.band),
                        size = 6, shape = 15) +
    ggplot2::geom_vline(xintercept = mean(model$performance, na.rm = TRUE)) +
    ggplot2::labs(title = title, x = "\nperformance", y = "importance\n") +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_y_continuous(limits = c(0, ymax), labels = label_pct()) +
    ggplot2::scale_x_continuous(limits = c(1, 5), breaks = 1:5) +
    theme_ezrsurvey_xy(transparent = TRUE)

  if (repel && requireNamespace("ggrepel", quietly = TRUE)) {
    p <- p + ggrepel::geom_text_repel(ggplot2::aes(label = .data$feature),
                                      size = 4, max.overlaps = 30)
  } else {
    p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$feature),
                                vjust = -1, size = 4)
  }

  annotate_bands(p, bands, axis = "x", at = ymax,
                 label_offset = ymax * 0.04)
}

#' Treemap of selected quotes
#'
#' A treemap where each tile is a comment sized by length -- the quote slides
#' from the original report. Requires the suggested `treemapify` package.
#'
#' @param data A data frame of quotes, e.g. from [sample_comments()].
#' @param label Text column (unquoted). Defaults to `comment`.
#' @param area Tile-size column (unquoted). Defaults to `length`.
#' @param colour Tile border colour. Defaults to `"black"`.
#'
#' @return A ggplot object.
#'
#' @details
#' Lays selected verbatims out as a treemap, each tile sized by comment length,
#' so a slide can show real customer voice at a glance. Pair it with
#' [sample_comments()] or [sample_comments_diverse()], which produce the
#' `comment`/`length` columns it expects. Requires the suggested `treemapify`
#' package.
#'
#' @family plots
#' @seealso [sample_comments()], [sample_comments_diverse()].
#' @examplesIf requireNamespace("treemapify", quietly = TRUE)
#' sample_comments(podracing_survey, nps_com, show_com, n = 5) %>%
#'   plot_quotes_tree()
#' @export
plot_quotes_tree <- function(data, label = comment, area = length,
                             colour = "black") {
  if (!requireNamespace("treemapify", quietly = TRUE)) {
    stop("Package 'treemapify' is required for plot_quotes_tree(). ",
         "Install it with install.packages('treemapify').", call. = FALSE)
  }
  label_sym <- rlang::ensym(label)
  area_sym <- rlang::ensym(area)

  ggplot2::ggplot(data, ggplot2::aes(area = !!area_sym, label = !!label_sym)) +
    treemapify::geom_treemap(fill = NA, colour = colour) +
    treemapify::geom_treemap_text(colour = "black", place = "center",
                                  grow = TRUE, reflow = TRUE,
                                  padding.x = ggplot2::unit(4, "mm"),
                                  padding.y = ggplot2::unit(4, "mm")) +
    theme_ezrsurvey(transparent = TRUE)
}
