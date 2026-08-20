# Internal: does `chat` look like an ellmer chat (anything with a $chat()
# method)? Ducks the class check so tests can inject a stub and other
# ellmer-compatible objects keep working.
is_chat_like <- function(chat) {
  !is.null(chat) && is.function(tryCatch(chat$chat, error = function(e) NULL))
}

# Internal: "- a\n- b" -> c("a", "b"); tolerates *, numbering and stray blanks.
parse_markdown_bullets <- function(text) {
  lines <- unlist(strsplit(text, "\n", fixed = TRUE))
  lines <- sub("^\\s*([-*+]|[0-9]+[.)])\\s+", "", trimws(lines))
  lines[nzchar(lines)]
}

#' Draft a slide title and takeaway bullets for a table
#'
#' Asks the model for the two pieces of text a chart slide needs: a
#' headline-style title stating the takeaway, and three or four takeaway
#' bullets to sit beside the chart. Returns them as plain strings for you to
#' place in whatever deck builder you use.
#'
#' @param data The summary table behind the slide.
#' @param title Optional working title for the table, given to the model as
#'   context. Not returned unless `want_title = FALSE`.
#' @param want_title Draft a headline title as well as bullets. Defaults to
#'   `TRUE`; set `FALSE` to keep your own titles and pay for one call instead
#'   of two.
#' @param chat An existing [ai_chat()] object reused across slides. If `NULL`,
#'   one is created from `provider` / `model`.
#' @param provider,model Passed to [ai_chat()] when `chat` is not supplied.
#' @param context Optional study context from [ai_context()], given to the
#'   model with the data.
#' @param max_rows Maximum rows of `data` to include. Defaults to the
#'   `max_rows` option.
#'
#' @return A list with `title` (a length-1 string, or `NULL`) and `bullets` (a
#'   character vector, or `NULL`). A failed call messages and returns `NULL` in
#'   that slot, so a network hiccup degrades to a plain slide rather than
#'   killing a deck build.
#'
#' @details
#' The two `slide_title` and `slide_bullets` prompt templates carry the
#' house style: the title states a so-what rather than a topic, and each bullet
#' is a self-contained finding a presenter can say out loud. Pass one `chat`
#' across every slide in a deck to reuse the connection.
#'
#' Everything is returned as text rather than written into a document, so it
#' drops into any deck builder: `officer::ph_with()` for a two-content layout,
#' `officer::set_notes()` for speaker notes, or a Quarto chunk that `cat()`s
#' the bullets.
#'
#' @family ai
#' @seealso [ai_summarise()], [ai_context()].
#' @examples
#' \dontrun{
#' gender <- data.frame(answer = c("Female", "Male"), pct = c(55, 45))
#' chat <- ai_chat()
#' text <- ai_slide_text(gender, title = "Gender", chat = chat)
#' text$title
#' text$bullets
#' }
#' @export
ai_slide_text <- function(data, title = NULL, want_title = TRUE, chat = NULL,
                          provider = ezrintelligence_default("provider"),
                          model = ezrintelligence_default("model"),
                          context = NULL,
                          max_rows = ezrintelligence_default("max_rows")) {
  if (is.null(chat)) {
    chat <- ai_chat(provider = provider, model = model,
                    system_prompt = get_prompt("slide_bullets")$system)
  }
  if (!is_chat_like(chat)) {
    stop("`chat` must be an ai_chat() object (or anything with a $chat() ",
         "method).", call. = FALSE)
  }
  label <- if (!is.null(title) && nzchar(title)) title else "this table"

  bullets_prompt <- build_prompt("slide_bullets", data = data, title = title,
                                 context = context, max_rows = max_rows)
  bullets <- tryCatch(
    parse_markdown_bullets(chat$chat(bullets_prompt)),
    error = function(e) {
      message("Slide bullets failed for '", label, "': ", conditionMessage(e))
      NULL
    }
  )

  drafted_title <- NULL
  if (want_title) {
    title_prompt <- build_prompt("slide_title", data = data, title = title,
                                 context = context, max_rows = max_rows)
    drafted_title <- tryCatch(
      trimws(chat$chat(title_prompt)),
      error = function(e) {
        message("Slide title failed for '", label, "': ", conditionMessage(e))
        NULL
      }
    )
  }
  list(title = drafted_title, bullets = bullets)
}
