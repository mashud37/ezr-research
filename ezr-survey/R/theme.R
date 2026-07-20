#' ezrsurvey ggplot2 themes
#'
#' A clean, presentation-oriented theme family generalised from the original
#' report themes (`theme_esl*`). The base theme strips chart junk -- no ticks,
#' no gridlines, centred bold titles -- which suits labelled bar charts that
#' carry their own data labels. The `_x` / `_y` / `_xy` variants add back faint
#' major gridlines on the named axes.
#'
#' @param base_size Base font size in points. Defaults to `11`.
#' @param base_family Base font family. `NULL` (default) uses the brand body
#'   font when one is set and installed (see [use_brand()]), else `"sans"`.
#' @param transparent If `TRUE`, make the plot, panel and legend backgrounds
#'   transparent (handy for slides). Defaults to `FALSE`.
#'
#' @return A [ggplot2::theme()] object to add to a plot with `+`.
#'
#' @details
#' A clean, presentation-first look: no axis ticks, no chart junk, bold centred
#' titles, and faint gridlines only where you ask for them. The base
#' `theme_ezrsurvey()` strips gridlines entirely (best for bar charts that carry
#' their own data labels); the `_x` / `_y` / `_xy` variants add back faint major
#' gridlines on the named axes. `transparent = TRUE` makes the backgrounds
#' transparent for slides. All the `plot_*()` helpers apply one of these for you.
#'
#' @family themes
#' @examples
#' df <- calc_percentage(podracing_survey, demo_gender)
#' ggplot(df, aes(demo_gender, pct)) + geom_col() + theme_ezrsurvey()
#' ggplot(df, aes(demo_gender, pct)) + geom_col() + theme_ezrsurvey_y()
#' @rdname theme_ezrsurvey
#' @export
theme_ezrsurvey <- function(base_size = 11, base_family = NULL,
                           transparent = FALSE) {
  base_family <- base_family %||% resolve_brand_family() %||% "sans"
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

.brand_font_notified <- new.env(parent = emptyenv())

# Internal: the brand body font, but only when brand fonts are enabled and the
# typeface is actually installed -- an unavailable family would make every
# chart render with substituted glyphs and ggplot warnings on this machine.
resolve_brand_family <- function() {
  if (!isTRUE(ezrsurvey_default("brand_fonts_enabled"))) return(NULL)
  family <- ezrsurvey_default("brand_font_minor")
  if (is.null(family) || !nzchar(family)) return(NULL)
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    notify_brand_font(family,
                      "install the 'systemfonts' package to use brand fonts")
    return(NULL)
  }
  info <- tryCatch(systemfonts::font_info(family), error = function(e) NULL)
  if (is.null(info) || !nrow(info) ||
      !identical(tolower(info$family[[1]]), tolower(family))) {
    notify_brand_font(family, "font not installed on this machine")
    return(NULL)
  }
  family
}

notify_brand_font <- function(family, why) {
  if (!isTRUE(.brand_font_notified[[family]])) {
    message("Brand font '", family, "' not applied (", why,
            "); using 'sans'.")
    .brand_font_notified[[family]] <- TRUE
  }
}

# Faint major gridline used by the axis variants.
.ezrsurvey_grid <- function() {
  ggplot2::element_line(colour = "grey97", linewidth = ggplot2::rel(.1))
}

#' @rdname theme_ezrsurvey
#' @export
theme_ezrsurvey_x <- function(base_size = 11, base_family = NULL,
                             transparent = FALSE) {
  theme_ezrsurvey(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = .ezrsurvey_grid(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(hjust = 0)
    )
}

#' @rdname theme_ezrsurvey
#' @export
theme_ezrsurvey_y <- function(base_size = 11, base_family = NULL,
                             transparent = FALSE) {
  theme_ezrsurvey(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = .ezrsurvey_grid()
    )
}

#' @rdname theme_ezrsurvey
#' @export
theme_ezrsurvey_xy <- function(base_size = 11, base_family = NULL,
                              transparent = FALSE) {
  theme_ezrsurvey(base_size, base_family, transparent) +
    ggplot2::theme(
      panel.grid.major.x = .ezrsurvey_grid(),
      panel.grid.major.y = .ezrsurvey_grid()
    )
}

#' Transparent-background theme fragment
#'
#' A small [ggplot2::theme()] fragment that makes the plot, panel and legend
#' backgrounds transparent. Add it to any theme for slide-friendly exports; the
#' `transparent` argument of [theme_ezrsurvey()] applies it for you.
#'
#' @return A [ggplot2::theme()] object.
#' @family themes
#' @examples
#' \dontrun{
#' ggplot(df, aes(x, y)) + geom_point() + theme_ezrsurvey() + theme_transparent()
#' }
#' @export
theme_transparent <- function() {
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
  )
}
