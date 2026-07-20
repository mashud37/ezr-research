require_xml2 <- function() {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("Package 'xml2' is required to read brand templates. ",
         "Install it with install.packages('xml2').", call. = FALSE)
  }
}

is_hex <- function(x) {
  grepl("^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$", x)
}

# Internal: locate and read the OOXML theme part inside a .pptx / .docx zip.
extract_ooxml_theme <- function(path) {
  if (!file.exists(path)) {
    stop("Template file '", path, "' does not exist.", call. = FALSE)
  }
  entries <- utils::unzip(path, list = TRUE)$Name
  themes <- sort(entries[grepl("(ppt|word)/theme/theme[0-9]+\\.xml$", entries)])
  if (!length(themes)) {
    stop("'", path, "' contains no OOXML theme part -- is it a valid ",
         ".pptx / .docx file?", call. = FALSE)
  }
  exdir <- tempfile("ezrsurvey-theme-")
  utils::unzip(path, files = themes[[1]], exdir = exdir)
  file.path(exdir, themes[[1]])
}

# Internal: parse an OOXML theme1.xml into brand colours and fonts.
parse_ooxml_theme <- function(xml_file) {
  require_xml2()
  ns <- c(a = "http://schemas.openxmlformats.org/drawingml/2006/main")
  doc <- xml2::read_xml(xml_file)

  read_color <- function(slot, fallback = NA_character_) {
    node <- xml2::xml_find_first(doc,
                                 paste0("//a:clrScheme/a:", slot), ns)
    if (inherits(node, "xml_missing")) return(fallback)
    val <- xml2::xml_attr(
      xml2::xml_find_first(node, "./a:srgbClr", ns), "val")
    if (is.na(val)) {
      # dk1/lt1 are usually system colours; lastClr records the resolved hex
      val <- xml2::xml_attr(
        xml2::xml_find_first(node, "./a:sysClr", ns), "lastClr")
    }
    if (is.na(val)) fallback else paste0("#", toupper(val))
  }

  read_font <- function(slot) {
    face <- xml2::xml_attr(
      xml2::xml_find_first(doc, paste0("//a:fontScheme/a:", slot, "/a:latin"),
                           ns), "typeface")
    if (is.na(face) || !nzchar(face) || grepl("^\\+", face)) NULL else face
  }

  accents <- vapply(paste0("accent", 1:6), read_color, character(1))
  accents <- unname(accents[!is.na(accents)])

  list(
    accents = accents,
    dark = read_color("dk1", "#000000"),
    light = read_color("lt1", "#FFFFFF"),
    font_major = read_font("majorFont"),
    font_minor = read_font("minorFont")
  )
}

#' Adopt an organisation brand from a PowerPoint or Word template
#'
#' Reads the colour and font theme out of your organisation's `.pptx` / `.docx`
#' template and makes it the session default for everything ezrsurvey produces:
#' charts pick up the brand accent colours and body font, and the template file
#' itself becomes the default reference document for [report_new()],
#' [report_deck()] and [scaffold_report()]. One call, and analysis output is
#' on-brand.
#'
#' @param template Path to a `.pptx` or `.docx` file. Its OOXML theme (accent
#'   colours, heading/body typefaces) is extracted, and the file is registered
#'   as the default reference document for reports of the matching format.
#'   `NULL` to set colours/fonts directly without a template.
#' @param colors Optional character vector of hex colours overriding the
#'   extracted accents. A single colour sets only the primary; a vector sets
#'   the full accent palette (first entry = primary). Invalid entries are
#'   dropped with a warning.
#' @param fonts Optional character vector overriding the extracted typefaces:
#'   either a single body font, or `c(major = "...", minor = "...")`.
#' @param quiet If `TRUE`, suppress the confirmation message.
#'
#' @return Invisibly a `ezrsurvey_brand` list (see [brand_info()]).
#'
#' @details
#' Extraction reads `theme1.xml` inside the template (requires the suggested
#' `xml2` package): accent colours 1-6 become `brand_colors` (first accent =
#' `brand_color_primary`, the default fill of [plot_bars()]), and the minor
#' (body) typeface becomes the default `base_family` of [theme_ezrsurvey()] --
#' but only when that font is actually installed on this machine, so charts
#' never render with substituted glyph boxes. Set
#' `ezrsurvey_options(brand_fonts_enabled = FALSE)` to keep brand colours but
#' ignore brand fonts.
#'
#' Everything lands in ordinary [ezrsurvey_options()] (`brand_*` keys), so you
#' can equally set the values by hand or persist them in a YAML profile; a
#' later `use_brand()` call simply overwrites them. Semantic palettes
#' ([pal_rating], [pal_nps]) deliberately keep their meaning-carrying colours
#' and are not rebranded. Use [clear_brand()] to return to the neutral look.
#'
#' @family brand
#' @seealso [brand_info()], [clear_brand()], [pal_brand()],
#'   [scale_fill_brand()], [report_new()], [scaffold_report()].
#' @examplesIf requireNamespace("xml2", quietly = TRUE) && requireNamespace("officer", quietly = TRUE)
#' tmp <- tempfile(fileext = ".pptx")
#' print(officer::read_pptx(), target = tmp)
#' use_brand(tmp, quiet = TRUE)
#' brand_info()
#' clear_brand()
#' @examples
#' # Or set brand values directly, no template needed:
#' use_brand(colors = c("#0B5394", "#E69138"), fonts = "Georgia", quiet = TRUE)
#' clear_brand()
#' @export
use_brand <- function(template = NULL, colors = NULL, fonts = NULL,
                      quiet = FALSE) {
  theme <- NULL
  if (!is.null(template)) {
    ext <- file_ext(template)
    if (!ext %in% c("pptx", "docx")) {
      stop("`template` must be a .pptx or .docx file.", call. = FALSE)
    }
    theme <- parse_ooxml_theme(extract_ooxml_theme(template))
    key <- paste0("brand_template_", ext)
    do.call(ezrsurvey_options,
            stats::setNames(list(normalizePath(template, winslash = "/")), key))
  }

  accents <- theme$accents
  primary <- if (length(accents)) accents[[1]] else NULL
  font_major <- theme$font_major
  font_minor <- theme$font_minor

  if (!is.null(colors)) {
    bad <- colors[!is_hex(colors)]
    if (length(bad)) {
      warning("Dropping invalid hex colour(s): ", paste(bad, collapse = ", "),
              call. = FALSE)
      colors <- colors[is_hex(colors)]
    }
    if (length(colors) == 1L) {
      primary <- colors
      accents <- accents %||% colors
    } else if (length(colors) > 1L) {
      accents <- colors
      primary <- colors[[1]]
    }
  }
  if (!is.null(fonts)) {
    nms <- names(fonts)
    if (is.null(nms)) {
      font_minor <- fonts[[1]]
    } else {
      if ("major" %in% nms) font_major <- fonts[["major"]]
      if ("minor" %in% nms) font_minor <- fonts[["minor"]]
    }
  }

  if (is.null(template) && is.null(colors) && is.null(fonts)) {
    stop("Provide a `template`, `colors`, or `fonts`.", call. = FALSE)
  }

  opts <- list(
    brand_colors = accents,
    brand_color_primary = primary,
    brand_font_major = font_major,
    brand_font_minor = font_minor
  )
  opts <- opts[!vapply(opts, is.null, logical(1))]
  if (length(opts)) do.call(ezrsurvey_options, opts)

  info <- brand_info()
  if (!quiet) print(info)
  invisible(info)
}

#' Show the active brand settings
#'
#' @return An `ezrsurvey_brand` list with elements `colors`, `color_primary`,
#'   `font_major`, `font_minor`, `template_pptx`, `template_docx` (each `NULL`
#'   when unset).
#' @family brand
#' @seealso [use_brand()], [clear_brand()].
#' @examples
#' brand_info()
#' @export
brand_info <- function() {
  structure(
    list(
      colors = ezrsurvey_default("brand_colors"),
      color_primary = ezrsurvey_default("brand_color_primary"),
      font_major = ezrsurvey_default("brand_font_major"),
      font_minor = ezrsurvey_default("brand_font_minor"),
      template_pptx = ezrsurvey_default("brand_template_pptx"),
      template_docx = ezrsurvey_default("brand_template_docx")
    ),
    class = "ezrsurvey_brand"
  )
}

#' @export
print.ezrsurvey_brand <- function(x, ...) {
  if (all(vapply(x, is.null, logical(1)))) {
    cat("No brand set. See ?use_brand.\n")
    return(invisible(x))
  }
  cat("ezrsurvey brand\n")
  if (!is.null(x$colors)) {
    cat("  colors:   ", paste(x$colors, collapse = " "), "\n", sep = "")
  }
  if (!is.null(x$color_primary)) {
    cat("  primary:  ", x$color_primary, "\n", sep = "")
  }
  if (!is.null(x$font_major) || !is.null(x$font_minor)) {
    cat("  fonts:    ",
        paste(c(x$font_major, x$font_minor), collapse = " / "), "\n", sep = "")
  }
  if (!is.null(x$template_pptx)) {
    cat("  pptx ref: ", x$template_pptx, "\n", sep = "")
  }
  if (!is.null(x$template_docx)) {
    cat("  docx ref: ", x$template_docx, "\n", sep = "")
  }
  invisible(x)
}

#' Clear the active brand
#'
#' Resets every `brand_*` option so charts and reports return to the neutral
#' ezrsurvey defaults.
#'
#' @return Invisibly `TRUE`.
#' @family brand
#' @seealso [use_brand()].
#' @examples
#' clear_brand()
#' @export
clear_brand <- function() {
  keys <- c("brand_colors", "brand_color_primary", "brand_font_major",
            "brand_font_minor", "brand_template_pptx", "brand_template_docx")
  options(stats::setNames(vector("list", length(keys)),
                          paste0("ezrsurvey.", keys)))
  invisible(TRUE)
}
