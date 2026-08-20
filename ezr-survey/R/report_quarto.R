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
#' with ezrsurvey helpers against the bundled `podracing_survey` data: an
#' executive summary, per-question sections with placeholder narrative, and a
#' methodology appendix built from the
#' precision diagnostics. Swap in your own data via the `data` parameter (or
#' at the top of the file) and render with Quarto. This is the document-driven
#' counterpart to the [report_new()] / [report_deck()] officer builders.
#'
#' @param format Output format: one of [list_report_templates()] (`"pptx"`,
#'   `"html"`, `"pdf"`, `"docx"`). Defaults to `"pptx"`.
#' @param path Destination `.qmd` path. If `NULL`, defaults to
#'   `"survey-report-<format>.qmd"` in the working directory.
#' @param title Title inserted into the template's YAML header.
#' @param author Author name for the YAML header. `NULL` leaves a placeholder.
#' @param reference_doc Path to a PowerPoint / Word template used as the
#'   Quarto `reference-doc` (pptx and docx formats only). `NULL` (default)
#'   uses the brand template registered by [use_brand()], if any; pptx then
#'   falls back to the package's built-in 16:9 template, docx leaves the line
#'   commented in the scaffold.
#' @param overwrite Overwrite `path` if it already exists. Defaults to `FALSE`.
#'
#' @return Invisibly the path written.
#'
#' @details
#' Each scaffold declares one Quarto parameter: `data`, the path to a CSV of
#' your survey; empty means the bundled example data.
#'
#' **Corporate templates:** Quarto/Pandoc fills a `reference-doc` by looking
#' for the *standard* layout names ("Title Slide", "Title and Content", "Two
#' Content", ...). A corporate template whose layouts keep those names works
#' directly; one with renamed layouts will render broken or blank slides here
#' -- build the deck with [report_deck()] instead, which inspects placeholders
#' and works with any template.
#'
#' @family reporting
#' @seealso [report_deck()] for building decks directly without Quarto;
#'   [use_brand()] to register a default reference document.
#' @examples
#' \dontrun{
#' scaffold_report("html", path = "report.qmd", title = "Q2 Viewer Survey")
#' scaffold_report("pptx", title = "Q2 Viewer Survey",
#'                 reference_doc = "brand/org-template.pptx")
#' # then: quarto::quarto_render("report.qmd")
#' }
#' @export
scaffold_report <- function(format = c("pptx", "html", "pdf", "docx"),
                            path = NULL, title = "Survey Report",
                            author = NULL, reference_doc = NULL,
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

  if (format %in% c("pptx", "docx")) {
    reference_doc <- reference_doc %||%
      ezrsurvey_default(paste0("brand_template_", format))
  }
  if (format == "pptx") {
    reference_doc <- reference_doc %||% default_pptx_template()
  }

  txt <- readLines(src, encoding = "UTF-8", warn = FALSE)
  txt <- gsub("{{TITLE}}", title, txt, fixed = TRUE)
  txt <- gsub("{{AUTHOR}}", author %||% "Your name", txt, fixed = TRUE)
  ref_line <- if (!is.null(reference_doc)) {
    paste0("    reference-doc: ",
           normalizePath(reference_doc, winslash = "/", mustWork = FALSE))
  } else {
    paste0("    # reference-doc: your-template.", format,
           "   # or scaffold_report(reference_doc = ...)")
  }
  txt[txt == "{{REFERENCE_DOC}}"] <- ref_line
  writeLines(txt, path, useBytes = TRUE)

  if (!requireNamespace("quarto", quietly = TRUE)) {
    message("Template written. Install the 'quarto' R package (and the Quarto ",
            "CLI) to render it: quarto::quarto_render('", path, "').")
  }
  invisible(path)
}

#' Copy the worked example report into a folder
#'
#' Drops the package's complete worked example next to your data: a full
#' Quarto report over the bundled `podracing_survey` (every chart type, real
#' narrative) plus the matching slide-deck script on the officer path. Render
#' / run them as they are, then swap in your own data.
#'
#' @param dir Destination folder. Defaults to `"ezrsurvey-example"` in the
#'   working directory; created if missing.
#' @param overwrite Overwrite existing files of the same names. Defaults to
#'   `FALSE`.
#'
#' @return Invisibly the paths written.
#'
#' @details
#' Two files are copied: `podracing-report.qmd` (render with
#' `quarto render podracing-report.qmd`) and `podracing-deck.R`
#' (run with `Rscript podracing-deck.R`;
#' writes a 16:9 deck to `ezrsurvey-outputs/`). Unlike the blank
#' [scaffold_report()]
#' skeletons, the example ships finished narrative over the bundled data, so
#' you can see every visual and slide element in a finished state before
#' adapting it.
#'
#' @family reporting
#' @seealso [scaffold_report()] for blank skeletons, [report_deck()].
#' @examples
#' \dontrun{
#' example_report()
#' quarto::quarto_render("ezrsurvey-example/podracing-report.qmd")
#' }
#' @export
example_report <- function(dir = "ezrsurvey-example", overwrite = FALSE) {
  src <- system.file("examples", package = "ezrsurvey")
  files <- list.files(src, full.names = TRUE)
  if (!length(files)) {
    stop("The installed package carries no examples folder.", call. = FALSE)
  }
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  dest <- file.path(dir, basename(files))
  clash <- dest[file.exists(dest)]
  if (length(clash) && !overwrite) {
    stop("Already there: ", paste(basename(clash), collapse = ", "),
         ". Use overwrite = TRUE to replace.", call. = FALSE)
  }
  ok <- file.copy(files, dest, overwrite = overwrite)
  if (!all(ok)) stop("Could not copy the example files.", call. = FALSE)
  message("Example written to ", dir, "/ -- start with podracing-report.qmd.")
  invisible(dest)
}
