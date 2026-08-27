#' Build a slide deck from a list of plots and tables in one call
#'
#' Turns a named list of ggplots / data frames into a titled-slide deck (or
#' Word document) and saves it. Names become slide titles; each item lands on
#' its own slide, sized to the template's content placeholder.
#'
#' @param items A named list; names become slide titles. Each element is either
#'   a ggplot (added as a plot) or a data frame (added as a table).
#' @param path Output file path. If `NULL` (default), the deck is written to
#'   `ezrsurvey-outputs/report.pptx` / `ezrsurvey-outputs/report.docx` in the
#'   working directory.
#' @param format `"pptx"` (default) or `"docx"`.
#' @param title Optional title-slide / document-title text.
#' @param template Optional reference document; `NULL` (default) uses the brand
#'   template registered by [use_brand()], see [report_new()].
#' @param style Built-in template to fall back on: `"elevated"` (default, the
#'   styled deck) or `"plain"` (undecorated white). See [report_new()].
#'
#' @return Invisibly `path`.
#'
#' @details
#' Every chart is rendered at the exact size of the template's content
#' placeholder and centred in it, and [plot_bars()] draws bars to a constant
#' thickness whatever the category count, so the deck reads consistently as you
#' flick through it.
#'
#' For a deck built a slide at a time, with section dividers and per-slide
#' control over the layout, use [report_new()] and the `report_add_*()` family
#' instead.
#'
#' @family reporting
#' @seealso [report_new()], [use_brand()].
#' @examples
#' \dontrun{
#' report_deck(
#'   list(
#'     "Gender" = plot_bars(calc_percentage(podracing_survey, demo_gender)),
#'     "NPS"    = calc_nps(podracing_survey, nps_value)
#'   ),
#'   path = "overview.pptx"
#' )
#' }
#' @export
report_deck <- function(items, path = NULL, format = c("pptx", "docx"),
                        title = NULL, template = NULL,
                        style = c("elevated", "plain")) {
  format <- match.arg(format)
  style <- match.arg(style)
  doc <- report_new(format, template = template, style = style)

  if (!is.null(title)) {
    if (format == "pptx") {
      sel <- select_layout(doc, "title")
      doc <- officer::add_slide(doc, layout = sel$layout, master = sel$master)
      set_report_state(doc, layout = sel$layout, master = sel$master)
      titles <- layout_placeholders(doc, sel$layout, sel$master,
                                    c("ctrTitle", "title"))
      if (nrow(titles)) {
        doc <- officer::ph_with(
          doc, value = title,
          location = officer::ph_location_type(titles$type[[1]])
        )
      }
    } else {
      doc <- officer::body_add_par(doc, title, style = "heading 1")
    }
  }

  nms <- names(items) %||% rep("", length(items))
  run <- progress_start(length(items),
                        paste0("Building ", length(items), " slide(s)"))
  for (i in seq_along(items)) {
    item <- items[[i]]
    nm <- nms[i]
    if (!inherits(item, "ggplot") && !is.data.frame(item)) {
      stop("Item '", nm, "' must be a ggplot or a data frame.", call. = FALSE)
    }
    progress_item(run, i, if (nzchar(nm)) nm else "(untitled)")

    doc <- report_add_slide(doc, title = if (nzchar(nm)) nm)

    doc <- if (inherits(item, "ggplot")) {
      report_add_plot(doc, item)
    } else {
      report_add_table(doc, item)
    }
  }
  progress_done(run)
  report_save(doc, path)
}
