#' ezrmodel ggplot2 themes
#'
#' A clean, presentation-oriented theme family generalised from the original
#' report themes (`theme_esl*`). The base theme strips chart junk -- no ticks,
#' no gridlines, centred bold titles -- which suits labelled bar charts that
#' carry their own data labels. The `_x` / `_y` / `_xy` variants add back faint
#' major gridlines on the named axes.
#'
#' @param base_size Base font size in points. Defaults to `11`.
#' @param base_family Base font family. Defaults to `"sans"`.
#' @param transparent If `TRUE`, make the plot, panel and legend backgrounds
#'   transparent (handy for slides). Defaults to `FALSE`.
#'
#' @return A [ggplot2::theme()] object to add to a plot with `+`.
#'
#' @details
#' A clean, presentation-first look: no axis ticks, no chart junk, bold centred
#' titles, and faint gridlines only where you ask for them. The base
#' `theme_ezrmodel()` strips gridlines entirely (best for bar charts that carry
#' their own data labels); the `_x` / `_y` / `_xy` variants add back faint major
#' gridlines on the named axes. `transparent = TRUE` makes the backgrounds
#' transparent for slides. All the `plot_*()` helpers apply one of these for you.
#'
#' @family themes
#' @examples
#' library(ggplot2)
#' df <- data.frame(group = c("a", "b", "c"), value = c(60, 30, 10))
#' ggplot(df, aes(group, value)) + geom_col() + theme_ezrmodel()
#' ggplot(df, aes(group, value)) + geom_col() + theme_ezrmodel_y()
#' @rdname theme_ezrmodel
#' @export
theme_ezrmodel <- function(base_size = 11, base_family = "sans",
                           transparent = FALSE) {
  t <- ggplot2::theme(
    axis.ticks = ggplot2::element_blank(),
    axis.title = ggplot2::element_text(face = "italic"),
    axis.text = ggplot2::element_text(size = ggplot2::rel(1.25)),
    legend.position = "none",
    plot.margin = ggplot2::unit(c(1, 1, 1, 1), "lines"),
    plot.title = ggplot2::element_text(face = "bold",
                                       size = ggplot2::rel(1.5), hjust = .5),
    plot.subtitle = ggplot2::element_text(face = "bold",
                                          size = ggplot2::rel(1.5), hjust = .5),
    panel.background = ggplot2::element_rect(fill = NA, colour = "white"),
    panel.grid.minor.x = ggplot2::element_blank(),
    panel.grid.minor.y = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    text = ggplot2::element_text(family = base_family, size = base_size),
    plot.title.position = "plot",
    plot.caption.position = "plot"
  )
  if (transparent) {
    t <- t + theme_transparent()
  }
  t
}

# Faint major gridline used by the axis variants.
.ezrmodel_grid <- function() {
  ggplot2::element_line(colour = "grey97", linewidth = ggplot2::rel(.1))
}

#' @rdname theme_ezrmodel
#' @export
theme_ezrmodel_x <- function(base_size = 11, base_family = "sans",
                             transparent = FALSE) {
  theme_ezrmodel(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = .ezrmodel_grid(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(hjust = 0)
    )
}

#' @rdname theme_ezrmodel
#' @export
theme_ezrmodel_y <- function(base_size = 11, base_family = "sans",
                             transparent = FALSE) {
  theme_ezrmodel(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = .ezrmodel_grid()
    )
}

#' @rdname theme_ezrmodel
#' @export
theme_ezrmodel_xy <- function(base_size = 11, base_family = "sans",
                              transparent = FALSE) {
  theme_ezrmodel(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = .ezrmodel_grid(),
      panel.grid.major.y = .ezrmodel_grid()
    )
}

#' Transparent-background theme fragment
#'
#' A small [ggplot2::theme()] fragment that makes the plot, panel and legend
#' backgrounds transparent. Add it to any theme for slide-friendly exports; the
#' `transparent` argument of [theme_ezrmodel()] applies it for you.
#'
#' @return A [ggplot2::theme()] object.
#' @family themes
#' @examples
#' \dontrun{
#' ggplot(df, aes(x, y)) + geom_point() + theme_ezrmodel() + theme_transparent()
#' }
#' @export
theme_transparent <- function() {
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
  )
}
