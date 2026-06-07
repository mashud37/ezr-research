# The chapter map that links exercises to the accompanying bookdown book.
.book_chapter_table <- function() {
  tibble::tribble(
    ~chapter, ~slug,                    ~title,
    1L, "fundamentals",            "R fundamentals",
    2L, "the-ezr-way",             "The ezr way",
    3L, "data-and-graphs",         "Data and graphs",
    4L, "finding-patterns",        "Finding patterns",
    5L, "segments-and-structure",  "Segments and structure",
    6L, "text",                    "Text",
    7L, "automation-and-reporting","Automation and reporting",
    8L, "practice",                "Practice"
  )
}

# Internal: base URL of the hosted book (override with the option).
book_base_url <- function() {
  getOption("ezrlearning.book_url",
            default = "https://aschellewald.github.io/ezr/")
}

#' The book chapters and their practice topics
#'
#' Returns the map that links the accompanying book to the practice exercises:
#' each chapter, the topics you can drill for it, and a URL into the hosted book.
#'
#' @return A [tibble][tibble::tibble] with `chapter`, `title`, `topics` (a
#'   comma-separated list), and `url`.
#'
#' @details
#' The exercise generators tag each question with the `chapter` it belongs to, so
#' this table is the bridge in both directions: from a chapter to "what can I
#' practise here" ([draw_exercise(chapter = n)][draw_exercise]) and from an
#' exercise back to the reading. The hosted book URL is taken from the
#' `ezrlearning.book_url` option (set it to point at your own build).
#'
#' @family book
#' @seealso [open_book()], [draw_exercise()], [list_topics()].
#' @examples
#' book_chapters()
#' @export
book_chapters <- function() {
  ch <- .book_chapter_table()
  topics <- list_topics()
  by_ch <- vapply(ch$chapter, function(k) {
    t <- topics$topic[topics$chapter == k]
    if (length(t)) paste(t, collapse = ", ") else ""
  }, character(1))
  tibble::tibble(
    chapter = ch$chapter,
    title = ch$title,
    topics = by_ch,
    url = paste0(book_base_url(), sprintf("%02d-%s.html", ch$chapter, ch$slug))
  )
}

#' Open the book (a chapter) in your browser
#'
#' Opens the hosted ezrlearning book, optionally at a specific chapter.
#'
#' @param chapter Optional chapter number (see [book_chapters()]). `NULL`
#'   (default) opens the book's front page.
#'
#' @return Invisibly the URL.
#'
#' @details
#' The URL comes from [book_chapters()] (and the `ezrlearning.book_url` option).
#' In a non-interactive session the URL is printed rather than opened. If you have
#' the book sources locally, build them with `bookdown::render_book("book")` and
#' point `options(ezrlearning.book_url = ...)` at your build.
#'
#' @family book
#' @seealso [book_chapters()].
#' @examples
#' open_book()          # prints the URL non-interactively
#' open_book(2)
#' @export
open_book <- function(chapter = NULL) {
  url <- if (is.null(chapter)) {
    book_base_url()
  } else {
    ch <- book_chapters()
    row <- ch[ch$chapter == chapter, , drop = FALSE]
    if (nrow(row) == 0L) {
      stop("No such chapter. See book_chapters().", call. = FALSE)
    }
    row$url[[1]]
  }
  if (interactive()) {
    utils::browseURL(url)
  } else {
    message("Book: ", url)
  }
  invisible(url)
}
