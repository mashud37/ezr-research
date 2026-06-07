# ---- Palette definitions -------------------------------------------------

#' ezrmodel colour palettes
#'
#' A small set of named palettes used by the `plot()` methods: a sequential ramp
#' for magnitudes (importances, loadings), a diverging ramp for signed values
#' (correlations from -1 to 1), and a qualitative set for cluster membership.
#'
#' @format Character vectors of hex colours:
#' \describe{
#'   \item{`pal_sequential`}{Five-step light-to-dark blue, for magnitudes.}
#'   \item{`pal_diverging`}{Amber -> grey -> green, for signed values such as
#'     correlations.}
#'   \item{`pal_qualitative`}{Eight distinct hues for categorical groups /
#'     clusters.}
#' }
#' @family themes
#' @aliases ezrmodel_palettes
#' @examplesIf requireNamespace("scales", quietly = TRUE)
#' scales::show_col(pal_qualitative)
#' @rdname ezrmodel_palettes
#' @export
pal_sequential <- c("#EFF3FF", "#BDD7E7", "#6BAED6", "#3182BD", "#08519C")

#' @rdname ezrmodel_palettes
#' @export
pal_diverging <- c("#FF3300", "#FFCB3E", "#F2F2F2", "#A7C23D", "#86A33B")

#' @rdname ezrmodel_palettes
#' @export
pal_qualitative <- c("#4E79A7", "#F28E2B", "#59A14F", "#E15759",
                     "#B07AA1", "#76B7B2", "#EDC948", "#9C755F")

# ---- ggplot2 scale helpers ----------------------------------------------

#' ezrmodel colour and fill scales
#'
#' Convenience ggplot2 scales over the [ezrmodel_palettes]: a continuous
#' sequential fill for magnitudes, a continuous diverging fill centred at zero
#' for signed values, and a discrete qualitative scale for clusters/groups.
#'
#' @param ... Passed to the underlying ggplot2 scale.
#' @param limit For `scale_fill_diverging()`, the symmetric absolute limit
#'   (defaults to `1`, i.e. correlations).
#'
#' @return A ggplot2 scale.
#' @family themes
#' @seealso [pal_sequential], [pal_diverging], [pal_qualitative]
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = letters[1:3], y = 1:3, g = factor(1:3))
#' ggplot(df, aes(x, y, fill = g)) + geom_col() + scale_fill_cluster()
#' @rdname ezrmodel_scales
#' @export
scale_fill_sequential <- function(...) {
  ggplot2::scale_fill_gradientn(colours = pal_sequential, ...)
}

#' @rdname ezrmodel_scales
#' @export
scale_fill_diverging <- function(..., limit = 1) {
  ggplot2::scale_fill_gradientn(colours = pal_diverging,
                                limits = c(-limit, limit), ...)
}

#' @rdname ezrmodel_scales
#' @export
scale_fill_cluster <- function(...) {
  ggplot2::scale_fill_manual(values = pal_qualitative, ...)
}

#' @rdname ezrmodel_scales
#' @export
scale_colour_cluster <- function(...) {
  ggplot2::scale_colour_manual(values = pal_qualitative, ...)
}

#' @rdname ezrmodel_scales
#' @export
scale_color_cluster <- scale_colour_cluster
