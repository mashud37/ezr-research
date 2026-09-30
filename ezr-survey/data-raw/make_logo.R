# Draws the package logo: man/figures/logo.png
#
# A pointy-top hexagon, the shape the R community uses for package stickers,
# styled the way Google styles its developer tools: a white surface, a hairline
# grey border, the name set in blue over a four-colour rule, and the qualifier
# in the grey Material reserves for secondary text. Base graphics only, so this
# needs nothing the package does not already depend on.
#
# Run from the package root: Rscript data-raw/make_logo.R

BLUE <- "#1A73E8"
GREY <- "#5F6368"
LINE <- "#BDC1C6"
PAPER <- "#FFFFFF"

# The four Material accents, in the order Google sets them.
ACCENTS <- c("#4285F4", "#EA4335", "#FBBC04", "#34A853")

hexagon <- function(x, y, radius) {
  angles <- (seq(0, 5) * 60 + 90) * pi / 180
  list(x = x + radius * cos(angles), y = y + radius * sin(angles))
}

# Base graphics has no letterspacing, so each character is placed by hand.
# Tracking is given as a share of the font size, the way a type designer would
# quote it, and the whole run is centred on x.
draw_tracked <- function(label, x, y, cex, colour, font, tracking) {
  chars <- strsplit(label, "")[[1]]
  widths <- strwidth(chars, cex = cex, font = font, family = "sans")
  gap <- tracking * strwidth("M", cex = cex, font = font, family = "sans")
  total <- sum(widths) + gap * (length(chars) - 1)

  left <- x - total / 2
  for (i in seq_along(chars)) {
    text(left + widths[[i]] / 2, y, chars[[i]], col = colour, cex = cex,
         font = font, family = "sans", adj = c(0.5, 0.5))
    left <- left + widths[[i]] + gap
  }
  invisible(total)
}

# Picks the cex that makes a tracked run come out the width asked for. Text
# scales linearly with cex, so one measurement at cex 1 settles it.
cex_for_width <- function(label, target, font, tracking) {
  chars <- strsplit(label, "")[[1]]
  at_one <- sum(strwidth(chars, cex = 1, font = font, family = "sans")) +
    tracking * strwidth("M", cex = 1, font = font, family = "sans") *
      (length(chars) - 1)
  target / at_one
}

# The rule under the name, split into the four accents.
draw_accent_rule <- function(x, y, width, height) {
  segment <- width / length(ACCENTS)
  left <- x - width / 2
  for (i in seq_along(ACCENTS)) {
    rect(left, y, left + segment, y + height, col = ACCENTS[[i]], border = NA)
    left <- left + segment
  }
}

build_logo <- function(path, px_wide = 480) {
  radius <- 1
  wide <- radius * sqrt(3)
  px_tall <- round(px_wide * 2 * radius / wide)

  grDevices::png(path, width = px_wide, height = px_tall, bg = "transparent",
                 res = 300, type = "cairo-png", antialias = "default")
  on.exit(grDevices::dev.off(), add = TRUE)
  par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(xlim = c(-wide / 2, wide / 2), ylim = c(-radius, radius),
              asp = 1)

  outer <- hexagon(0, 0, radius)
  polygon(outer$x, outer$y, col = LINE, border = NA)
  inner <- hexagon(0, 0, radius * 0.94)
  polygon(inner$x, inner$y, col = PAPER, border = NA)

  big <- cex_for_width("EZR", target = 0.92, font = 2, tracking = 0.10)
  small <- cex_for_width("survey", target = 0.82, font = 1, tracking = 0.30)

  draw_tracked("EZR", 0, 0.21, cex = big, colour = BLUE, font = 2,
               tracking = 0.10)
  draw_accent_rule(0, -0.05, width = 0.92, height = 0.035)
  draw_tracked("survey", 0, -0.27, cex = small, colour = GREY, font = 1,
               tracking = 0.30)

  invisible(path)
}

if (!dir.exists(file.path("man", "figures"))) {
  dir.create(file.path("man", "figures"), recursive = TRUE)
}
out <- file.path("man", "figures", "logo.png")
build_logo(out)
message("Wrote ", out, " (", file.size(out), " bytes)")
