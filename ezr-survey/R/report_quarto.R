#' Available Quarto report templates
#'
#' @return A character vector of the output formats ezrsurvey ships a Quarto
#'   skeleton for.
#' @family reporting
#' @seealso [scaffold_report()].
#' @examples
#' list_report_templates()
#' @export
list_report_templates <- function() {
  files <- list.files(system.file("templates", package = "ezrsurvey"),
                      pattern = "^report-.*\\.qmd$")
  sub("^report-(.*)\\.qmd$", "\\1", files)
}

#' Scaffold a Quarto survey-report template
#'
#' Copies a ready-to-render Quarto report skeleton into your project, wired up
#' with ezrsurvey helpers (NPS gauge, importance/performance, percentage bars,
#' precision diagnostics) against the bundled `consumer_survey` data. Swap in
#' your own data at the top and render with Quarto. This is the document-driven
#' counterpart to the [report_new()] / [report_deck()] officer builders.
#'
#' @param format Output format: one of [list_report_templates()] (`"pptx"`,
#'   `"html"`, `"pdf"`, `"docx"`). Defaults to `"pptx"`.
#' @param path Destination `.qmd` path. If `NULL`, defaults to
#'   `"survey-report-<format>.qmd"` in the working directory.
#' @param title Title inserted into the template's YAML header.
#' @param overwrite Overwrite `path` if it already exists. Defaults to `FALSE`.
#'
#' @return Invisibly the path written.
#' @family reporting
#' @seealso [report_deck()] for building decks directly without Quarto.
#' @examples
#' \dontrun{
#' scaffold_report("html", path = "report.qmd", title = "Q2 Viewer Survey")
#' # then: quarto::quarto_render("report.qmd")
#' }
#' @export
scaffold_report <- function(format = c("pptx", "html", "pdf", "docx"),
                            path = NULL, title = "Survey Report",
                            overwrite = FALSE) {
  format <- match.arg(format)
  src <- system.file("templates", paste0("report-", format, ".qmd"),
                     package = "ezrsurvey")
  if (!nzchar(src)) {
    stop("No bundled template for format '", format, "'.", call. = FALSE)
  }
  if (is.null(path)) {
    path <- paste0("survey-report-", format, ".qmd")
  }
  if (file.exists(path) && !overwrite) {
    stop("'", path, "' already exists. Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }

  txt <- readLines(src, encoding = "UTF-8", warn = FALSE)
  txt <- gsub("{{TITLE}}", title, txt, fixed = TRUE)
  writeLines(txt, path, useBytes = TRUE)

  if (!requireNamespace("quarto", quietly = TRUE)) {
    message("Template written. Install the 'quarto' R package (and the Quarto ",
            "CLI) to render it: quarto::quarto_render('", path, "').")
  }
  invisible(path)
}
