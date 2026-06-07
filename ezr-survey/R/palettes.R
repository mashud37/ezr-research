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
#' @family themes
#' @rdname ezrsurvey_palettes
#' @examples
#' pal_rating
#' @examplesIf requireNamespace("scales", quietly = TRUE)
#' scales::show_col(pal_rating)
#' @export
pal_rating <- c(
  "1" = "#FF3300",
  "2" = "#FFCB3E",
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

# ---- ggplot2 scale helpers ----------------------------------------------

#' Rating colour and fill scales
#'
#' Manual ggplot2 scales mapping a 1-5 rating (as a factor or its character
#' codes `"1"`..`"5"`) onto the [pal_rating] red-amber-green palette.
#'
#' @param distinct If `TRUE`, use a fully distinct 5-colour ramp (points 1 and 2
#'   differ); if `FALSE` (default) use the report's `pal_rating` where 2 and 3
#'   share amber. The distinct ramp suits stacked bars.
#' @param ... Passed to [ggplot2::scale_fill_manual()] /
#'   [ggplot2::scale_colour_manual()].
#'
#' @return A ggplot2 scale.
#'
#' @details
#' Maps the rating codes `"1"`..`"5"` onto [pal_rating]. With `distinct = FALSE`
#' (default) points 2 and 3 share amber, matching the source reports; set
#' `distinct = TRUE` for a fully distinct 5-colour ramp, which reads better on
#' stacked bars. `scale_color_rating()` is an alias of `scale_colour_rating()`.
#'
#' @family themes
#' @seealso [pal_rating], [scale_fill_nps()].
#' @examples
#' library(ggplot2)
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
#' library(ggplot2)
#' df <- data.frame(score = 0:2, pct = c(20, 30, 50), group = c(-1, 0, 1))
#' ggplot(df, aes(score, pct, fill = factor(group))) +
#'   geom_col() +
#'   scale_fill_nps()
#' @export
scale_fill_nps <- function(...) {
  ggplot2::scale_fill_manual(values = pal_nps, ...)
}
