require_officer <- function() {
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("Package 'officer' is required for the report builders. ",
         "Install it with install.packages('officer').", call. = FALSE)
  }
}

require_flextable <- function() {
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop("Package 'flextable' is required for report tables. ",
         "Install it with install.packages('flextable').", call. = FALSE)
  }
}

is_pptx <- function(doc) inherits(doc, "rpptx")
is_docx <- function(doc) inherits(doc, "rdocx")

check_doc <- function(doc) {
  if (!is_pptx(doc) && !is_docx(doc)) {
    stop("`doc` must be an ezrsurvey report (see report_new()).", call. = FALSE)
  }
}

#' Start a new PowerPoint or Word report
#'
#' Opens a blank \pkg{officer} document you can build up with the
#' `report_add_*()` helpers and write out with [report_save()]. This is the
#' "build slides/Word directly from R" path; for a Quarto-based workflow see
#' [scaffold_report()].
#'
#' @param format `"pptx"` (default) for PowerPoint or `"docx"` for Word.
#' @param template Optional path to a `.pptx` / `.docx` to use as the style
#'   template (reference doc). If `NULL`, officer's blank default is used.
#'
#' @return An officer document object (`rpptx` or `rdocx`).
#'
#' @details
#' This is the "build it from R" path: you get a blank \pkg{officer} document and
#' add to it slide by slide (pptx) or section by section (docx) with the
#' `report_add_*()` helpers, then write it out with [report_save()]. For a quick
#' deck from a list of charts and tables, [report_deck()] does the whole thing in
#' one call; for a document-driven workflow, [scaffold_report()] gives you a
#' Quarto template instead. Requires the suggested `officer` package.
#'
#' @family reporting
#' @seealso [report_add_slide()], [report_add_plot()], [report_add_table()],
#'   [report_save()], [report_deck()].
#' @examples
#' \dontrun{
#' doc <- report_new("pptx")
#' }
#' @export
report_new <- function(format = c("pptx", "docx"), template = NULL) {
  require_officer()
  format <- match.arg(format)
  if (format == "pptx") {
    officer::read_pptx(path = template)
  } else {
    officer::read_docx(path = template)
  }
}

#' Add a slide (PowerPoint) or heading (Word) to a report
#'
#' For a `pptx` document this starts a new slide and sets its title; for a `docx`
#' document it adds a heading paragraph.
#'
#' @param doc A document from [report_new()].
#' @param title Optional slide title / heading text.
#' @param layout,master PowerPoint layout and master names. Defaults to the
#'   standard `"Title and Content"` / `"Office Theme"`.
#' @param heading_level Word heading level (1-3). Defaults to `1`.
#'
#' @return The updated document (invisibly side-effecting officer object).
#' @family reporting
#' @seealso [report_new()].
#' @examples
#' \dontrun{
#' doc <- report_new("pptx") |> report_add_slide("Audience")
#' }
#' @export
report_add_slide <- function(doc, title = NULL, layout = "Title and Content",
                             master = "Office Theme", heading_level = 1) {
  check_doc(doc)
  if (is_pptx(doc)) {
    doc <- officer::add_slide(doc, layout = layout, master = master)
    if (!is.null(title)) {
      doc <- officer::ph_with(doc, value = title,
                              location = officer::ph_location_type("title"))
    }
  } else if (!is.null(title)) {
    doc <- officer::body_add_par(doc, title,
                                 style = paste("heading", heading_level))
  }
  doc
}

#' Add a plot to a report
#'
#' Renders a ggplot to an image and places it on the current slide (pptx) or as
#' a new figure (docx).
#'
#' @param doc A document from [report_new()].
#' @param plot A ggplot object.
#' @param width,height Image size in inches. Defaults to `9 x 5` (pptx body) /
#'   `6 x 3.5` (docx).
#' @param dpi Raster resolution. Defaults to `150`.
#'
#' @return The updated document.
#' @family reporting
#' @seealso [report_add_table()].
#' @examples
#' \dontrun{
#' p <- calc_percentage(consumer_survey, demo_gender) |> plot_bars()
#' report_new("pptx") |> report_add_slide("Gender") |> report_add_plot(p)
#' }
#' @export
report_add_plot <- function(doc, plot, width = NULL, height = NULL, dpi = 150) {
  check_doc(doc)
  width <- width %||% (if (is_pptx(doc)) 9 else 6)
  height <- height %||% (if (is_pptx(doc)) 5 else 3.5)

  tmp <- tempfile(fileext = ".png")
  ggplot2::ggsave(tmp, plot = plot, width = width, height = height,
                  dpi = dpi, bg = "white")
  img <- officer::external_img(tmp, width = width, height = height)

  if (is_pptx(doc)) {
    officer::ph_with(doc, value = img,
                     location = officer::ph_location_type("body"))
  } else {
    officer::body_add_img(doc, src = tmp, width = width, height = height)
  }
}

#' Add a table to a report
#'
#' Adds a data frame as a \pkg{flextable} -- on the current slide (pptx) or as a
#' new table (docx).
#'
#' @param doc A document from [report_new()].
#' @param data A data frame / tibble.
#' @param autofit Auto-size columns to content. Defaults to `TRUE`.
#'
#' @return The updated document.
#' @family reporting
#' @seealso [report_add_plot()].
#' @examples
#' \dontrun{
#' tbl <- calc_percentage(consumer_survey, demo_gender)
#' report_new("docx") |> report_add_table(tbl)
#' }
#' @export
report_add_table <- function(doc, data, autofit = TRUE) {
  check_doc(doc)
  require_flextable()
  ft <- flextable::flextable(as.data.frame(data))
  if (autofit) ft <- flextable::autofit(ft)

  if (is_pptx(doc)) {
    officer::ph_with(doc, value = ft,
                     location = officer::ph_location_type("body"))
  } else {
    flextable::body_add_flextable(doc, ft)
  }
}

#' Add a paragraph of text to a report
#'
#' @param doc A document from [report_new()].
#' @param text Text to add.
#' @param ... Passed to [officer::body_add_par()] (docx) or used as the body
#'   placeholder (pptx).
#'
#' @return The updated document.
#' @family reporting
#' @examples
#' \dontrun{
#' report_new("docx") |> report_add_text("Key findings follow.")
#' }
#' @export
report_add_text <- function(doc, text, ...) {
  check_doc(doc)
  if (is_pptx(doc)) {
    officer::ph_with(doc, value = text,
                     location = officer::ph_location_type("body"))
  } else {
    officer::body_add_par(doc, text, ...)
  }
}

#' Save a report to disk
#'
#' @param doc A document from [report_new()].
#' @param path Output file path (`.pptx` or `.docx`).
#'
#' @return Invisibly `path`.
#' @family reporting
#' @examples
#' \dontrun{
#' report_new("pptx") |> report_add_slide("Hi") |> report_save("out.pptx")
#' }
#' @export
report_save <- function(doc, path) {
  check_doc(doc)
  print(doc, target = path)
  invisible(path)
}

#' Build a slide deck from a list of plots and tables in one call
#'
#' A convenience wrapper that turns a named list of ggplots / data frames into a
#' titled-slide deck (or Word document) and saves it.
#'
#' @param items A named list; names become slide titles. Each element is either
#'   a ggplot (added as a plot) or a data frame (added as a table).
#' @param path Output file path.
#' @param format `"pptx"` (default) or `"docx"`.
#' @param title Optional title-slide / document-title text.
#' @param template Optional reference document; see [report_new()].
#'
#' @return Invisibly `path`.
#' @family reporting
#' @seealso [report_new()].
#' @examples
#' \dontrun{
#' report_deck(
#'   list(
#'     "Gender" = plot_bars(calc_percentage(consumer_survey, demo_gender)),
#'     "NPS"    = calc_nps(consumer_survey, nps_value)
#'   ),
#'   path = "overview.pptx"
#' )
#' }
#' @export
report_deck <- function(items, path, format = c("pptx", "docx"),
                        title = NULL, template = NULL) {
  format <- match.arg(format)
  doc <- report_new(format, template = template)

  if (!is.null(title)) {
    if (format == "pptx") {
      doc <- officer::add_slide(doc, layout = "Title Slide",
                                master = "Office Theme")
      doc <- officer::ph_with(doc, value = title,
                              location = officer::ph_location_type("ctrTitle"))
    } else {
      doc <- officer::body_add_par(doc, title, style = "heading 1")
    }
  }

  nms <- names(items) %||% rep("", length(items))
  for (i in seq_along(items)) {
    item <- items[[i]]
    doc <- report_add_slide(doc, title = if (nzchar(nms[i])) nms[i] else NULL)
    if (inherits(item, "ggplot")) {
      doc <- report_add_plot(doc, item)
    } else if (is.data.frame(item)) {
      doc <- report_add_table(doc, item)
    } else {
      stop("Item '", nms[i], "' must be a ggplot or a data frame.",
           call. = FALSE)
    }
  }
  report_save(doc, path)
}
