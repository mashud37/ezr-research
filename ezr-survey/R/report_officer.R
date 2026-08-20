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

# Per-document state: the layout of the most recently added slide (so plot and
# table placement can read that layout's placeholder geometry) and one-shot
# warning flags. Keyed by the document's private unpack directory, which is
# stable for the lifetime of an rpptx object.
.report_state <- new.env(parent = emptyenv())

report_state <- function(doc) {
  key <- doc$package_dir
  if (is.null(.report_state[[key]])) .report_state[[key]] <- list()
  .report_state[[key]]
}

set_report_state <- function(doc, ...) {
  key <- doc$package_dir
  state <- report_state(doc)
  new <- list(...)
  state[names(new)] <- new
  .report_state[[key]] <- state
  invisible(state)
}

# Internal: the 16:9 lightly styled template the package ships (see
# data-raw/make_default_template.R). Standard layout names, so it also serves
# as a Quarto / Pandoc reference-doc.
default_pptx_template <- function(style = c("elevated", "plain")) {
  style <- match.arg(style)
  file <- if (style == "plain") "ezrsurvey-16x9-plain.pptx" else
    "ezrsurvey-16x9.pptx"
  path <- system.file("templates", file, package = "ezrsurvey")
  if (nzchar(path)) path else NULL
}

# Internal: layout_properties() of the current document, with only the columns
# placement needs. Decoration shapes without a <p:ph> element (officer reports
# them as type "body" with an NA ph) are dropped so they never masquerade as
# content placeholders.
layout_props <- function(doc) {
  props <- officer::layout_properties(doc)
  if ("ph" %in% names(props)) {
    props <- props[!is.na(props$ph), , drop = FALSE]
  }
  props[, intersect(c("master_name", "name", "type", "id", "ph_label",
                      "offx", "offy", "cx", "cy"),
                    names(props)), drop = FALSE]
}

# Internal: choose the layout best suited to `purpose` by scoring placeholder
# *types* (layout names are locale-dependent, so names only break ties).
select_layout <- function(doc, purpose = c("content", "title", "two_content")) {
  purpose <- match.arg(purpose)
  props <- layout_props(doc)
  groups <- split(props, paste(props$master_name, props$name, sep = "\r"))

  score_one <- function(g) {
    n_body <- sum(g$type == "body")
    has_title <- any(g$type == "title")
    has_ctr <- any(g$type == "ctrTitle")
    nm <- tolower(g$name[[1]])
    switch(
      purpose,
      content = 2 * has_title + 2 * (n_body == 1) + 1 * (n_body > 1) -
        2 * has_ctr + 0.5 * grepl("content|body|inhalt|contenu", nm),
      title = 3 * has_ctr + 0.5 * has_title + 1 * grepl("title|titel|titre", nm),
      two_content = 3 * (n_body == 2 && has_title) +
        0.5 * grepl("two|comparison|zwei|deux", nm)
    )
  }
  scores <- vapply(groups, score_one, numeric(1))
  if (purpose == "two_content" && max(scores) < 3) return(NULL)
  best <- groups[[which.max(scores)]]
  list(layout = best$name[[1]], master = best$master_name[[1]])
}

# Internal: placeholder rows of `type` for a layout, in reading order.
layout_placeholders <- function(doc, layout, master, type = "body") {
  props <- layout_props(doc)
  rows <- props[props$name == layout & props$master_name == master &
                  props$type %in% type, , drop = FALSE]
  if (nrow(rows) > 1) {
    ord <- order(ifelse(is.na(rows$offy), Inf, rows$offy),
                 ifelse(is.na(rows$offx), Inf, rows$offx))
    rows <- rows[ord, , drop = FALSE]
  }
  rows
}

# Internal: where (and how large) content should land on the current slide.
# Returns list(location, width, height); geometry falls back from the layout's
# body placeholder to the slide size minus margins to a fixed 9 x 5.
content_slot <- function(doc, index = 1) {
  state <- report_state(doc)
  rows <- NULL
  if (!is.null(state$layout)) {
    rows <- layout_placeholders(doc, state$layout, state$master, "body")
  }
  if (!is.null(rows) && nrow(rows) >= index) {
    row <- rows[index, , drop = FALSE]
    if (!is.na(row$cx) && !is.na(row$cy) && row$cx > 0 && row$cy > 0) {
      loc <- if (!is.na(row$ph_label) && nzchar(row$ph_label)) {
        officer::ph_location_label(ph_label = row$ph_label)
      } else {
        officer::ph_location(left = row$offx, top = row$offy,
                             width = row$cx, height = row$cy)
      }
      return(list(location = loc, width = row$cx, height = row$cy))
    }
  }
  size <- tryCatch(officer::slide_size(doc), error = function(e) NULL)
  if (!is.null(size)) {
    w <- size$width - 1
    h <- size$height - 2.25
    return(list(
      location = officer::ph_location(left = 0.5, top = 1.75,
                                      width = w, height = h),
      width = w, height = h
    ))
  }
  list(location = officer::ph_location(left = 0.5, top = 1.75,
                                       width = 9, height = 5),
       width = 9, height = 5)
}

# Internal: the <p:sp> node of the slide-number placeholder defined by
# `layout`, read from the document's unpacked template files. NULL when the
# layout defines none.
slide_number_node <- function(doc, layout) {
  dir <- file.path(doc$package_dir, "ppt", "slideLayouts")
  files <- list.files(dir, pattern = "^slideLayout[0-9]+[.]xml$",
                      full.names = TRUE)
  for (f in files) {
    x <- xml2::read_xml(f)
    nm <- xml2::xml_attr(xml2::xml_find_first(x, "//p:cSld"), "name")
    if (identical(nm, layout)) {
      node <- xml2::xml_find_first(x, "//p:sp[.//p:ph[@type='sldNum']]")
      if (inherits(node, "xml_missing")) return(NULL)
      return(node)
    }
  }
  NULL
}

# Internal: copy the layout's slide-number placeholder (which carries the
# live slide-number field) onto the current slide. officer does not carry
# footer placeholders over to new slides, so without this the numbers a
# template defines never render. Best-effort: does nothing without xml2, on
# title layouts, or when the layout defines no slide-number placeholder.
add_slide_number <- function(doc, layout, master) {
  if (!requireNamespace("xml2", quietly = TRUE)) return(doc)
  titles <- layout_placeholders(doc, layout, master, "ctrTitle")
  if (nrow(titles)) return(doc)
  node <- tryCatch(slide_number_node(doc, layout),
                   error = function(e) NULL)
  if (is.null(node)) return(doc)
  slide <- tryCatch(doc$slide$get_slide(doc$cursor)$get(),
                    error = function(e) NULL)
  if (is.null(slide)) return(doc)
  tree <- xml2::xml_find_first(slide, "//p:cSld/p:spTree")
  if (inherits(tree, "xml_missing")) return(doc)
  copy <- xml2::xml_add_child(tree, node)
  id_node <- xml2::xml_find_first(copy, ".//p:cNvPr")
  if (!inherits(id_node, "xml_missing")) {
    xml2::xml_set_attr(id_node, "id", as.character(900 + doc$cursor))
  }
  doc
}

#' List the slide layouts of a PowerPoint template
#'
#' Shows what a template offers the report builders: every layout, its master,
#' and the placeholders it carries. Useful to decide which `layout` to name in
#' [report_add_slide()], or to sanity-check an organisation template before
#' building a deck against it.
#'
#' @param template Path to a `.pptx`, an existing document from [report_new()],
#'   or `NULL` (default) for the brand template registered by [use_brand()]
#'   (falling back to a built-in template, see `style`).
#' @param style Built-in template to inspect when no `template` and no brand
#'   template are set: `"elevated"` (default) or `"plain"`. See [report_new()].
#'
#' @return A [tibble][tibble::tibble] with one row per layout: `layout`,
#'   `master`, `has_title`, `n_body`, `body_width`, `body_height` (inches of
#'   the first body placeholder, `NA` when the layout has none).
#'
#' @details
#' The report builders pick layouts automatically by inspecting placeholders,
#' so most decks never need this -- but when a corporate template offers
#' several content layouts, `report_layouts()` plus an explicit
#' `report_add_slide(layout = ...)` gives you full control. Requires the
#' suggested `officer` package.
#'
#' @family reporting
#' @seealso [report_new()], [report_add_slide()], [use_brand()].
#' @examplesIf requireNamespace("officer", quietly = TRUE)
#' report_layouts()
#' @export
report_layouts <- function(template = NULL, style = c("elevated", "plain")) {
  require_officer()
  style <- match.arg(style)
  doc <- if (is_pptx(template)) {
    template
  } else {
    path <- template %||% ezrsurvey_default("brand_template_pptx") %||%
      default_pptx_template(style)
    officer::read_pptx(path = path)
  }
  props <- layout_props(doc)
  groups <- split(props, paste(props$master_name, props$name, sep = "\r"))
  rows <- lapply(groups, function(g) {
    body <- g[g$type == "body", , drop = FALSE]
    tibble::tibble(
      layout = g$name[[1]],
      master = g$master_name[[1]],
      has_title = any(g$type %in% c("title", "ctrTitle")),
      n_body = nrow(body),
      body_width = if (nrow(body)) round(body$cx[[1]], 2) else NA_real_,
      body_height = if (nrow(body)) round(body$cy[[1]], 2) else NA_real_
    )
  })
  dplyr::bind_rows(rows)
}

#' Start a new PowerPoint or Word report
#'
#' Opens an \pkg{officer} document you can build up with the `report_add_*()`
#' helpers and write out with [report_save()]. This is the "build slides/Word
#' directly from R" path; for a Quarto-based workflow see [scaffold_report()].
#'
#' @param format `"pptx"` (default) for PowerPoint or `"docx"` for Word.
#' @param template Optional path to a `.pptx` / `.docx` to use as the style
#'   template (reference doc). `NULL` (default) uses the brand template
#'   registered by [use_brand()], falling back to one of the package's built-in
#'   16:9 templates (see `style`).
#' @param style Which built-in template to fall back on when no `template` and
#'   no brand template are set. `"elevated"` (default) is the styled deck: a
#'   navy/gold identity with a full-bleed navy cover, full-bleed navy section
#'   dividers, a navy title over one slim rule on every content slide and slide
#'   numbers in the corner. `"plain"` is the same widescreen deck with the same
#'   palette but no decoration -- plain white slides. Ignored when a template is
#'   supplied.
#' @param slide_numbers If `TRUE` (default), every content slide added with
#'   [report_add_slide()] shows the template's slide-number placeholder in
#'   its usual corner. Requires the suggested `xml2` package (silently skipped
#'   without it, or when the template has no slide-number placeholder).
#'
#' @return An officer document object (`rpptx` or `rdocx`).
#'
#' @details
#' This is the "build it from R" path: you get an \pkg{officer} document and
#' add to it slide by slide (pptx) or section by section (docx) with the
#' `report_add_*()` helpers, then write it out with [report_save()]. Slide
#' layouts are chosen by inspecting the template's placeholders, so any
#' organisation template works -- see [report_layouts()] for what yours
#' contains. For a quick deck from a list of charts and tables, [report_deck()]
#' does the whole thing in one call; for a document-driven workflow,
#' [scaffold_report()] gives you a Quarto template instead. Requires the
#' suggested `officer` package.
#'
#' @family reporting
#' @seealso [report_add_slide()], [report_add_plot()], [report_add_table()],
#'   [report_save()], [report_deck()], [report_layouts()], [use_brand()].
#' @examples
#' \dontrun{
#' doc <- report_new("pptx")
#' doc <- report_new("pptx", template = "brand/org-template.pptx")
#' }
#' @export
report_new <- function(format = c("pptx", "docx"), template = NULL,
                       style = c("elevated", "plain"), slide_numbers = TRUE) {
  require_officer()
  format <- match.arg(format)
  style <- match.arg(style)
  template <- template %||%
    ezrsurvey_default(paste0("brand_template_", format))
  if (format == "pptx") {
    template <- template %||% default_pptx_template(style)
    doc <- officer::read_pptx(path = template)
    set_report_state(doc, slide_numbers = isTRUE(slide_numbers))
    doc
  } else {
    officer::read_docx(path = template)
  }
}

#' Add a slide (PowerPoint) or heading (Word) to a report
#'
#' For a `pptx` document this starts a new slide and sets its title; for a
#' `docx` document it adds a heading paragraph.
#'
#' @param doc A document from [report_new()].
#' @param title Optional slide title / heading text.
#' @param layout,master PowerPoint layout and master names. `NULL` (default)
#'   picks the template's best content layout automatically (by inspecting
#'   placeholders, so corporate templates with renamed layouts work). Name a
#'   layout from [report_layouts()] to override.
#' @param heading_level Word heading level (1-3). Defaults to `1`.
#'
#' @return The updated document.
#'
#' @details
#' Automatic selection scores every layout of the template: a title
#' placeholder plus a single content placeholder is the ideal, and the layout's
#' *placeholders* decide -- not its (language-dependent) name. If the chosen
#' layout has no title placeholder, the title is skipped with a warning rather
#' than failing the build.
#'
#' @family reporting
#' @seealso [report_new()], [report_layouts()].
#' @examples
#' \dontrun{
#' doc <- report_new("pptx") %>% report_add_slide("Audience")
#' }
#' @export
report_add_slide <- function(doc, title = NULL, layout = NULL,
                             master = NULL, heading_level = 1) {
  check_doc(doc)
  if (!is_pptx(doc)) {
    if (!is.null(title)) {
      doc <- officer::body_add_par(doc, title,
                                   style = paste("heading", heading_level))
    }
    return(doc)
  }

  if (is.null(layout)) {
    sel <- select_layout(doc, "content")
  } else {
    summ <- officer::layout_summary(doc)
    hit <- summ[summ$layout == layout, , drop = FALSE]
    if (!is.null(master)) hit <- hit[hit$master == master, , drop = FALSE]
    if (!nrow(hit)) {
      stop("Layout '", layout, "' not found in this template. ",
           "See report_layouts() for what it offers.", call. = FALSE)
    }
    sel <- list(layout = hit$layout[[1]], master = hit$master[[1]])
  }

  doc <- officer::add_slide(doc, layout = sel$layout, master = sel$master)
  set_report_state(doc, layout = sel$layout, master = sel$master)
  if (!isFALSE(report_state(doc)$slide_numbers)) {
    doc <- add_slide_number(doc, sel$layout, sel$master)
  }

  if (!is.null(title)) {
    titles <- layout_placeholders(doc, sel$layout, sel$master,
                                  c("title", "ctrTitle"))
    if (nrow(titles)) {
      type <- titles$type[[1]]
      doc <- officer::ph_with(doc, value = title,
                              location = officer::ph_location_type(type))
    } else {
      state <- report_state(doc)
      if (!isTRUE(state$warned_title)) {
        warning("Layout '", sel$layout, "' has no title placeholder; ",
                "slide titles are skipped.", call. = FALSE)
        set_report_state(doc, warned_title = TRUE)
      }
    }
  }
  doc
}

#' Add a plot to a report
#'
#' Renders a ggplot to an image and places it in the current slide's content
#' placeholder (pptx) or as a new figure (docx).
#'
#' @param doc A document from [report_new()].
#' @param plot A ggplot object (any grid grob also works, e.g. an aligned
#'   plot from [report_deck()]'s alignment step).
#' @param width,height Image size in inches. `NULL` (default) sizes the image
#'   to the slide's content placeholder (pptx) or `6 x 3.5` (docx), so charts
#'   fill whatever template the deck is built on.
#' @param dpi Raster resolution. Defaults to `150`.
#'
#' @return The updated document.
#'
#' @details
#' On slides the image is rendered at exactly the content placeholder's size,
#' so nothing is stretched or letterboxed; when the template does not define
#' placeholder geometry the slide size (minus margins) is used instead.
#'
#' @family reporting
#' @seealso [report_add_table()].
#' @examples
#' \dontrun{
#' p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
#' report_new("pptx") %>% report_add_slide("Gender") %>% report_add_plot(p)
#' }
#' @export
report_add_plot <- function(doc, plot, width = NULL, height = NULL, dpi = 150) {
  check_doc(doc)
  if (is_pptx(doc)) {
    slot <- content_slot(doc)
    width <- width %||% slot$width
    height <- height %||% slot$height
    tmp <- tempfile(fileext = ".png")
    ggplot2::ggsave(tmp, plot = plot, width = width, height = height,
                    dpi = dpi, bg = "white")
    img <- officer::external_img(tmp, width = width, height = height)
    officer::ph_with(doc, value = img, location = slot$location)
  } else {
    width <- width %||% 6
    height <- height %||% 3.5
    tmp <- tempfile(fileext = ".png")
    ggplot2::ggsave(tmp, plot = plot, width = width, height = height,
                    dpi = dpi, bg = "white")
    officer::body_add_img(doc, src = tmp, width = width, height = height)
  }
}

#' Add a table to a report
#'
#' Adds a data frame as a \pkg{flextable} -- in the current slide's content
#' placeholder (pptx) or as a new table (docx).
#'
#' @param doc A document from [report_new()].
#' @param data A data frame / tibble.
#' @param font_size Cell font size in points. Defaults to `12`.
#' @param autofit Word only: auto-size columns to content. Defaults to `TRUE`.
#'   On slides the table is always sized to fill the content placeholder.
#'
#' @return The updated document.
#'
#' @details
#' On a slide the table is styled (a clean banded header, centred cells, a
#' readable font) and its columns are widened to span the content placeholder
#' -- roughly in proportion to each column's contents -- so it fills the slide
#' meaningfully instead of sitting tiny in a corner. In Word it is added as a
#' plain auto-fitted \pkg{flextable}.
#'
#' @family reporting
#' @seealso [report_add_plot()].
#' @examples
#' \dontrun{
#' tbl <- calc_percentage(podracing_survey, demo_gender)
#' report_new("docx") %>% report_add_table(tbl)
#' }
#' @export
report_add_table <- function(doc, data, font_size = 12, autofit = TRUE) {
  check_doc(doc)
  require_flextable()
  df <- as.data.frame(data)
  ft <- flextable::flextable(df)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::bold(ft, part = "header")
  ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::padding(ft, padding = 4, part = "all")

  if (is_pptx(doc)) {
    slot <- content_slot(doc)
    # Widen columns to span the placeholder, roughly proportional to how much
    # text each holds, so a summary table fills the slide instead of clustering
    # at its natural (tiny) content width.
    wt <- vapply(names(df), function(k) {
      cells <- suppressWarnings(max(nchar(format(df[[k]])), na.rm = TRUE))
      max(nchar(k), if (is.finite(cells)) cells else 0L, 3L)
    }, numeric(1))
    ft <- flextable::width(ft, width = slot$width * wt / sum(wt))
    officer::ph_with(doc, value = ft, location = slot$location)
  } else {
    if (autofit) ft <- flextable::autofit(ft)
    flextable::body_add_flextable(doc, ft)
  }
}

#' Add a paragraph of text to a report
#'
#' @param doc A document from [report_new()].
#' @param text Text to add; a character vector becomes one paragraph (bullet)
#'   per element on slides.
#' @param ... Passed to [officer::body_add_par()] (docx only).
#'
#' @return The updated document.
#' @family reporting
#' @examples
#' \dontrun{
#' report_new("docx") %>% report_add_text("Key findings follow.")
#' }
#' @export
report_add_text <- function(doc, text, ...) {
  check_doc(doc)
  if (is_pptx(doc)) {
    officer::ph_with(doc, value = text, location = content_slot(doc)$location)
  } else {
    for (line in text) doc <- officer::body_add_par(doc, line, ...)
    doc
  }
}

#' Add a whole slide in one call (title plus its content)
#'
#' The one-line-per-slide wrapper: starts a new slide, sets its title, and
#' places `content` on it in a single call, so a deck script reads as one line
#' per slide. `content` is dispatched by type -- a ggplot becomes a chart, a
#' data frame a table, a character vector a bulleted text box.
#'
#' @param doc A document from [report_new()].
#' @param title Slide title (typically the survey question the slide answers).
#' @param content A ggplot, a data frame / tibble, or a character vector. `NULL`
#'   (default) adds an empty titled slide.
#' @param layout,master Passed to [report_add_slide()]; `NULL` auto-selects.
#' @param ... Passed on to [report_add_plot()], [report_add_table()] or
#'   [report_add_text()] depending on `content`.
#'
#' @return The updated document.
#'
#' @details
#' Equivalent to [report_add_slide()] followed by the matching `report_add_*()`
#' call, but as one pipe-friendly step so `calc -> plot -> add` collapses onto a
#' single line:
#' `report_slide("How likely to recommend?", plot_nps(nps_value))`.
#'
#' @family reporting
#' @seealso [report_section()], [report_title_slide()], [report_add_slide()].
#' @examples
#' \dontrun{
#' report_new("pptx") %>%
#'   report_slide("Who follows pod racing?",
#'                plot_bars(calc_percentage(podracing_survey, demo_gender)))
#' }
#' @export
report_slide <- function(doc, title = NULL, content = NULL, layout = NULL,
                         master = NULL, ...) {
  check_doc(doc)
  doc <- report_add_slide(doc, title = title, layout = layout, master = master)
  if (is.null(content)) return(doc)
  if (inherits(content, "ggplot")) {
    report_add_plot(doc, content, ...)
  } else if (is.data.frame(content)) {
    report_add_table(doc, content, ...)
  } else if (is.character(content)) {
    report_add_text(doc, content, ...)
  } else {
    stop("`content` must be a ggplot, a data frame, or a character vector.",
         call. = FALSE)
  }
}

#' Add a section-divider slide
#'
#' A one-line section break: a slide on the template's "Section Header" layout
#' (falling back to a plain titled slide when the template has none). Use a
#' short, single-word label -- `"DEMOGRAPHICS"`, `"RATINGS"`, `"APPENDIX"` -- to
#' chapter a deck.
#'
#' @param doc A document from [report_new()].
#' @param title Section label.
#' @param layout Section layout name. Defaults to `"Section Header"`.
#' @param master Optional master name.
#'
#' @return The updated document.
#' @family reporting
#' @seealso [report_slide()], [report_title_slide()].
#' @examples
#' \dontrun{
#' report_new("pptx") %>% report_section("DEMOGRAPHICS")
#' }
#' @export
report_section <- function(doc, title, layout = "Section Header",
                           master = NULL) {
  check_doc(doc)
  if (!is_pptx(doc)) {
    return(report_add_slide(doc, title, heading_level = 1))
  }
  has_layout <- layout %in% officer::layout_summary(doc)$layout
  if (has_layout) {
    report_add_slide(doc, title, layout = layout, master = master)
  } else {
    report_add_slide(doc, title)
  }
}

#' Add the opening title slide
#'
#' A one-line title slide, placed on the template's title layout (the one with a
#' centre-title placeholder).
#'
#' @param doc A document from [report_new()].
#' @param title Deck title.
#' @param subtitle Optional strapline placed in the layout's subtitle
#'   placeholder -- the respondent base and fieldwork period, say. `NULL`
#'   (default) leaves it empty.
#' @param layout,master Optional overrides; `NULL` auto-selects the title
#'   layout.
#'
#' @return The updated document.
#' @family reporting
#' @seealso [report_slide()], [report_section()].
#' @examples
#' \dontrun{
#' report_new("pptx") %>%
#'   report_title_slide("Pod-Racing Fan Survey",
#'                      subtitle = "1,000 fans | Fieldwork 2026")
#' }
#' @export
report_title_slide <- function(doc, title, subtitle = NULL, layout = NULL,
                               master = NULL) {
  check_doc(doc)
  if (!is_pptx(doc)) {
    doc <- report_add_slide(doc, title, heading_level = 1)
    if (!is.null(subtitle)) doc <- officer::body_add_par(doc, subtitle)
    return(doc)
  }
  if (is.null(layout)) {
    sel <- select_layout(doc, "title")
    layout <- sel$layout
    master <- master %||% sel$master
  }
  doc <- report_add_slide(doc, title, layout = layout, master = master)
  if (!is.null(subtitle)) {
    subs <- layout_placeholders(doc, layout, master, c("subTitle", "body"))
    if (nrow(subs)) {
      doc <- officer::ph_with(
        doc, value = subtitle,
        location = officer::ph_location_type(type = subs$type[[1]])
      )
    }
  }
  doc
}

#' Save a report to disk
#'
#' @param doc A document from [report_new()].
#' @param path Output file path (`.pptx` or `.docx`). If `NULL` (default), the
#'   report is written to `ezrsurvey-outputs/report.pptx` /
#'   `ezrsurvey-outputs/report.docx` in the working directory. Missing
#'   directories are created.
#'
#' @return Invisibly `path`.
#' @family reporting
#' @examples
#' \dontrun{
#' report_new("pptx") %>% report_add_slide("Hi") %>% report_save("out.pptx")
#' }
#' @export
report_save <- function(doc, path = NULL) {
  check_doc(doc)
  ext <- if (is_pptx(doc)) "pptx" else "docx"
  path <- ensure_output_dir(path %||% default_output_path("report", ext))
  print(doc, target = path)
  invisible(path)
}
