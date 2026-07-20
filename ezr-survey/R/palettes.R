# ---- Palette definitions -------------------------------------------------

#' ezrsurvey colour palettes
#'
#' A small set of named, semantic palettes generalised from the original survey
#' reports. Each is a plain character vector of hex colours (some named) that you
#' can use directly or via the `scale_*_rating()` / `scale_fill_nps()` helpers.
#'
#' @format Each palette is a character vector of hex colour strings:
#' \describe{
#'   \item{`pal_rating`}{Five-point red -> amber -> green scale for 1-5 ratings,
#'     named `"1"`..`"5"`.}
#'   \item{`pal_nps`}{Three NPS-group colours, named `"-1"`, `"0"`, `"1"`
#'     (detractor / passive / promoter).}
#'   \item{`pal_sequential_blue`}{Four-step sequential blue, light to dark, for
#'     ordered brand questions.}
#'   \item{`pal_neutral`}{A single neutral grey used for unbranded single-series
#'     bars.}
#' }
#'
#' @details
#' These are the semantic colour vocabularies behind the plot helpers: red ->
#' amber -> green for ratings (worse to better), a matching three-colour NPS
#' scale, a sequential blue for ordered brand questions, and a neutral grey for
#' plain single-series bars. Use them directly, or via the
#' [scale_fill_rating()] / [scale_fill_nps()] ggplot2 scales.
#'
#' `pal_rating` follows the same thresholds as [bands_rating_3()]: ratings of 1
#' and 2 are BAD (red), 3 is OK (amber), 4 and 5 are GOOD (green). Keeping the
#' two in step matters -- a point coloured amber sitting inside a red band is
#' the kind of contradiction that quietly misleads a reader.
#'
#' @family themes
#' @rdname ezrsurvey_palettes
#' @examples
#' pal_rating
#' @examplesIf requireNamespace("scales", quietly = TRUE)
#' scales::show_col(pal_rating)
#' @export
pal_rating <- c(
  "1" = "#FF3300",
  "2" = "#FF3300",
  "3" = "#FFCB3E",
  "4" = "#A7C23D",
  "5" = "#86A33B"
)

#' @rdname ezrsurvey_palettes
#' @export
pal_nps <- c(
  "-1" = "#FF3300",
  "0"  = "#FFCB3E",
  "1"  = "#86A33B"
)

#' @rdname ezrsurvey_palettes
#' @export
pal_sequential_blue <- c(
  "#8FE2FF", "#43CEFF", "#00B0F0", "#0070C0"
)

#' @rdname ezrsurvey_palettes
#' @export
pal_neutral <- "#D9D9D9"

# Full 5-step rating ramp (distinct colour per point) for stacked rating bars,
# where points 1 and 2 should be visually distinct.
pal_rating5 <- c(
  "1" = "#EC2000",
  "2" = "#FF3300",
  "3" = "#FFCB3E",
  "4" = "#A7C23D",
  "5" = "#86A33B"
)

# Build a red -> amber -> green fill palette keyed on the *actual* level labels
# (e.g. "1 - Very bad"), mapping each by its leading 1-9 digit so worse-to-better
# reads low-to-high. A standard 1-5 scale reuses the report's `pal_rating5`
# exactly; other lengths (3-, 7-point, ...) interpolate the same anchors.
rating_palette <- function(level_labels) {
  labs <- if (is.factor(level_labels)) {
    levels(level_labels)
  } else {
    unique(as.character(level_labels))
  }
  labs <- labs[!is.na(labs)]
  nums <- suppressWarnings(as.integer(stringr::str_extract(labs, "[1-9]")))
  if (length(labs) && all(!is.na(nums)) && max(nums) <= 5) {
    cols <- unname(pal_rating5[as.character(nums)])
  } else {
    ramp <- grDevices::colorRampPalette(c("#FF3300", "#FFCB3E", "#86A33B"))
    cols <- ramp(length(labs))[rank(nums, ties.method = "first")]
  }
  stats::setNames(cols, labs)
}

# ---- Brand palette -------------------------------------------------------

#' Brand colour palette
#'
#' Returns the organisation's accent colours set by [use_brand()] (or the
#' `brand_colors` option), ready for manual scales or direct use. Without a
#' brand, it falls back to [pal_sequential_blue] so it always returns something
#' usable.
#'
#' @param n Number of colours wanted. `NULL` (default) returns the full accent
#'   vector as-is; when `n` exceeds the available colours the palette is
#'   interpolated with [grDevices::colorRampPalette()].
#'
#' @return A character vector of hex colours.
#'
#' @details
#' Only the *categorical* brand accents live here. The semantic palettes
#' ([pal_rating], [pal_nps]) keep their red-amber-green vocabulary regardless
#' of brand -- recolouring "bad to good" with corporate accents would destroy
#' the meaning the colours carry.
#'
#' @family brand
#' @seealso [use_brand()], [scale_fill_brand()].
#' @examples
#' pal_brand()      # sequential blue until a brand is set
#' pal_brand(2)
#' @export
pal_brand <- function(n = NULL) {
  cols <- ezrsurvey_default("brand_colors") %||%
    ezrsurvey_default("brand_color_primary") %||%
    pal_sequential_blue
  cols <- unname(cols)
  if (is.null(n)) return(cols)
  if (n <= length(cols)) return(cols[seq_len(n)])
  grDevices::colorRampPalette(cols)(n)
}

#' Brand fill and colour scales
#'
#' Discrete ggplot2 scales using the brand accent palette from [pal_brand()].
#' `scale_color_brand()` is an alias of `scale_colour_brand()`.
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#'
#' @return A ggplot2 scale.
#'
#' @details
#' The palette function interpolates when a plot needs more colours than the
#' brand defines, so the scale never runs out. Without a brand set, the scales
#' fall back to the [pal_sequential_blue] defaults via [pal_brand()].
#'
#' @family brand
#' @seealso [pal_brand()], [use_brand()].
#' @examples
#' df <- calc_percentage(podracing_survey, demo_gender)
#' ggplot(df, aes(demo_gender, pct, fill = demo_gender)) +
#'   geom_col() +
#'   scale_fill_brand()
#' @rdname scale_brand
#' @export
scale_fill_brand <- function(...) {
  ggplot2::discrete_scale("fill", palette = function(n) pal_brand(n), ...)
}

#' @rdname scale_brand
#' @export
scale_colour_brand <- function(...) {
  ggplot2::discrete_scale("colour", palette = function(n) pal_brand(n), ...)
}

#' @rdname scale_brand
#' @export
scale_color_brand <- scale_colour_brand

# ---- ggplot2 scale helpers ----------------------------------------------

#' Rating colour and fill scales
#'
#' Manual ggplot2 scales mapping a 1-5 rating (as a factor or its character
#' codes `"1"`..`"5"`) onto the [pal_rating] red-amber-green palette.
#'
#' @param distinct If `TRUE`, use a fully distinct 5-colour ramp where each
#'   point has its own shade; if `FALSE` (default) use [pal_rating], where 1 and
#'   2 share red and 4 and 5 share green. The distinct ramp suits stacked bars,
#'   where neighbouring segments need to be told apart.
#' @param ... Passed to [ggplot2::scale_fill_manual()] /
#'   [ggplot2::scale_colour_manual()].
#'
#' @return A ggplot2 scale.
#'
#' @details
#' Maps the rating codes `"1"`..`"5"` onto [pal_rating], which uses the
#' [bands_rating_3()] thresholds (1-2 bad, 3 ok, 4-5 good). Set
#' `distinct = TRUE` for a fully distinct 5-colour ramp, which reads better on
#' stacked bars where adjacent segments must be separable.
#' `scale_color_rating()` is an alias of `scale_colour_rating()`.
#'
#' @family themes
#' @seealso [pal_rating], [scale_fill_nps()].
#' @examples
#' df <- data.frame(feature = c("a", "b"), pct = c(60, 40), rating = c(4, 2))
#' ggplot(df, aes(feature, pct, fill = factor(rating))) +
#'   geom_col() +
#'   scale_fill_rating()
#' @rdname scale_rating
#' @export
scale_fill_rating <- function(distinct = FALSE, ...) {
  ggplot2::scale_fill_manual(values = if (distinct) pal_rating5 else pal_rating, ...)
}

#' @rdname scale_rating
#' @export
scale_colour_rating <- function(distinct = FALSE, ...) {
  ggplot2::scale_colour_manual(values = if (distinct) pal_rating5 else pal_rating, ...)
}

#' @rdname scale_rating
#' @export
scale_color_rating <- scale_colour_rating

#' NPS group fill scale
#'
#' Manual fill scale mapping the NPS-group coding (`"-1" / "0" / "1"`) onto the
#' [pal_nps] palette.
#'
#' @param ... Passed to [ggplot2::scale_fill_manual()].
#'
#' @return A ggplot2 scale.
#'
#' @details
#' Maps the NPS-group coding from [nps_group()] (`"-1"` detractor, `"0"` passive,
#' `"1"` promoter) onto the [pal_nps] red/amber/green palette, so the colours
#' carry their usual meaning. Used by [plot_nps()].
#'
#' @family themes
#' @seealso [pal_nps], [nps_group()], [plot_nps()].
#' @examples
#' df <- data.frame(score = 0:2, pct = c(20, 30, 50), group = c(-1, 0, 1))
#' ggplot(df, aes(score, pct, fill = factor(group))) +
#'   geom_col() +
#'   scale_fill_nps()
#' @export
scale_fill_nps <- function(...) {
  ggplot2::scale_fill_manual(values = pal_nps, ...)
}
