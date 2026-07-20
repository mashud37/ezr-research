# Internal: does `chat` look like an ellmer chat (anything with a $chat()
# method)? Ducks the class check so tests can inject a stub and other
# ellmer-compatible objects keep working.
is_chat_like <- function(chat) {
  !is.null(chat) && is.function(tryCatch(chat$chat, error = function(e) NULL))
}

# Internal: the summary table behind a deck item -- data frames as-is, ggplots
# via the summary table they were built from. NULL when there is nothing
# sensible to describe.
item_table <- function(item) {
  if (is.data.frame(item)) return(item)
  if (inherits(item, "ggplot") && is.data.frame(item$data) &&
      nrow(item$data)) {
    return(item$data)
  }
  NULL
}

# Internal: "- a\n- b" -> c("a", "b"); tolerates *, numbering and stray blanks.
parse_markdown_bullets <- function(text) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE))
  lines <- sub("^\\s*([-*+]|[0-9]+[.)])\\s+", "", trimws(lines))
  lines[nzchar(lines)]
}

# Internal: generate slide text for one deck item; failures message and return
# NULLs so the deck still builds.
deck_ai_text <- function(chat, tbl, name, context, want_title, max_rows = 50) {
  out <- list(title = NULL, bullets = NULL)
  bullets_prompt <- build_prompt("slide_bullets", data = tbl,
                                 title = if (nzchar(name)) name,
                                 context = context, max_rows = max_rows)
  out$bullets <- tryCatch(
    parse_markdown_bullets(chat$chat(bullets_prompt)),
    error = function(e) {
      message("AI bullets failed for '", name, "': ", conditionMessage(e))
      NULL
    }
  )
  if (want_title) {
    title_prompt <- build_prompt("slide_title", data = tbl,
                                 title = if (nzchar(name)) name,
                                 context = context, max_rows = max_rows)
    out$title <- tryCatch(
      trimws(chat$chat(title_prompt)),
      error = function(e) {
        message("AI title failed for '", name, "': ", conditionMessage(e))
        NULL
      }
    )
  }
  out
}

#' Build a slide deck from a list of plots and tables in one call
#'
#' Turns a named list of ggplots / data frames into a titled-slide deck (or
#' Word document) and saves it. With `ai = TRUE`, an LLM drafts takeaway
#' bullets -- and, on request, headline titles -- for every slide from the data
#' behind it.
#'
#' @param items A named list; names become slide titles. Each element is either
#'   a ggplot (added as a plot) or a data frame (added as a table).
#' @param path Output file path. If `NULL` (default), the deck is written to
#'   `outputs/report.pptx` / `outputs/report.docx` in the working directory.
#' @param format `"pptx"` (default) or `"docx"`.
#' @param title Optional title-slide / document-title text.
#' @param template Optional reference document; `NULL` (default) uses the brand
#'   template registered by [use_brand()], see [report_new()].
#' @param style Built-in template to fall back on: `"elevated"` (default, the
#'   styled deck) or `"plain"` (undecorated white). See [report_new()].
#' @param ai If `TRUE`, draft 3-4 takeaway bullets per slide with an LLM (the
#'   `slide_bullets` prompt template). Defaults to `FALSE`.
#' @param ai_titles If `TRUE`, also let the LLM write a headline-style title
#'   for every slide. Your own item names are never overwritten unless you set
#'   this; unnamed items always get an AI title when `ai = TRUE`.
#' @param chat An existing [ai_chat()] object reused for all slides. If `NULL`,
#'   one is created from `provider` / `model`.
#' @param provider,model Passed to [ai_chat()] when `chat` is not supplied.
#' @param context Optional survey context from [ai_context()], given to the
#'   model with every slide's data.
#'
#' @return Invisibly `path`.
#'
#' @details
#' Where the AI text lands depends on the template: if it offers a
#' two-content layout (title plus two content placeholders), the chart goes
#' left and the bullets right; otherwise the bullets are written into the
#' slide's speaker notes, which works on any template and survives import into
#' Google Slides. In Word, bullets become paragraphs under the section
#' heading. One chat connection is reused across all slides, and any failed
#' call is reported and skipped, so a network hiccup degrades to a plain slide
#' rather than killing the build.
#'
#' Every chart is rendered at the exact size of the template's content
#' placeholder and centred in it, and [plot_bars()] draws bars to a constant
#' thickness whatever the category count, so the deck reads consistently as you
#' flick through it.
#'
#' Privacy: with `ai = TRUE`, the summary tables behind the items (never raw
#' respondent rows) are sent to the LLM provider.
#'
#' @family reporting
#' @seealso [report_new()], [ai_context()], [use_brand()].
#' @examples
#' \dontrun{
#' report_deck(
#'   list(
#'     "Gender" = plot_bars(calc_percentage(podracing_survey, demo_gender)),
#'     "NPS"    = calc_nps(podracing_survey, nps_value)
#'   ),
#'   path = "overview.pptx"
#' )
#'
#' # the same deck with AI takeaway bullets on every slide
#' report_deck(
#'   list(
#'     "Gender" = plot_bars(calc_percentage(podracing_survey, demo_gender)),
#'     "NPS"    = calc_nps(podracing_survey, nps_value)
#'   ),
#'   path = "overview.pptx", ai = TRUE, provider = "openai",
#'   context = ai_context(podracing_survey)
#' )
#' }
#' @export
report_deck <- function(items, path = NULL, format = c("pptx", "docx"),
                        title = NULL, template = NULL,
                        style = c("elevated", "plain"), ai = FALSE,
                        ai_titles = FALSE, chat = NULL, provider = "openai",
                        model = NULL, context = NULL) {
  format <- match.arg(format)
  style <- match.arg(style)
  doc <- report_new(format, template = template, style = style)

  if (ai) {
    if (is.null(chat)) {
      require_ellmer()
      chat <- ai_chat(provider = provider, model = model,
                      system_prompt = get_prompt("slide_bullets")$system)
    }
    if (!is_chat_like(chat)) {
      stop("`chat` must be an ai_chat() object (or anything with a $chat() ",
           "method).", call. = FALSE)
    }
  }

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
  for (i in seq_along(items)) {
    item <- items[[i]]
    nm <- nms[i]
    if (!inherits(item, "ggplot") && !is.data.frame(item)) {
      stop("Item '", nm, "' must be a ggplot or a data frame.", call. = FALSE)
    }

    ai_text <- list(title = NULL, bullets = NULL)
    if (ai) {
      tbl <- item_table(item)
      if (is.null(tbl)) {
        message("Skipping AI text for '", nm, "': no summary table behind it.")
      } else {
        ai_text <- deck_ai_text(chat, tbl, nm, context,
                                want_title = ai_titles || !nzchar(nm))
      }
    }
    slide_title <- ai_text$title %||% (if (nzchar(nm)) nm)

    two_col <- NULL
    if (format == "pptx" && !is.null(ai_text$bullets)) {
      two_col <- select_layout(doc, "two_content")
    }

    if (!is.null(two_col)) {
      doc <- report_add_slide(doc, title = slide_title,
                              layout = two_col$layout,
                              master = two_col$master)
    } else {
      doc <- report_add_slide(doc, title = slide_title)
    }

    doc <- if (inherits(item, "ggplot")) {
      report_add_plot(doc, item)
    } else {
      report_add_table(doc, item)
    }

    if (!is.null(ai_text$bullets)) {
      if (format == "pptx" && !is.null(two_col)) {
        slot2 <- content_slot(doc, index = 2)
        doc <- officer::ph_with(doc, value = ai_text$bullets,
                                location = slot2$location)
      } else if (format == "pptx") {
        doc <- officer::set_notes(
          doc, value = paste(ai_text$bullets, collapse = "\n"),
          location = officer::notes_location_type("body")
        )
      } else {
        for (b in ai_text$bullets) {
          doc <- officer::body_add_par(doc, b, style = "Normal")
        }
      }
    }
  }
  report_save(doc, path)
}
