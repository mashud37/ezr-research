# Draws the package logo: man/figures/logo.png
#
# A pointy-top hexagon, the shape the R community uses for package stickers, in
# the navy and gold the bundled deck template already carries. The name is set
# as type rather than as a picture: EZR in letterspaced capitals, a gold rule,
# then survey beneath it. Base graphics only, so this needs nothing the package
# does not already depend on.
#
# Run from the package root: Rscript data-raw/make_logo.R

NAVY <- "#12314E"
GOLD <- "#C9A227"
PAPER <- "#FFFFFF"

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
  polygon(outer$x, outer$y, col = GOLD, border = NA)
  inner <- hexagon(0, 0, radius * 0.93)
  polygon(inner$x, inner$y, col = NAVY, border = NA)

  big <- cex_for_width("EZR", target = 0.92, font = 2, tracking = 0.16)
  small <- cex_for_width("survey", target = 0.86, font = 1, tracking = 0.34)

  draw_tracked("EZR", 0, 0.20, cex = big, colour = PAPER, font = 2,
               tracking = 0.16)
  rect(-0.46, -0.055, 0.46, -0.03, col = GOLD, border = NA)
  draw_tracked("survey", 0, -0.26, cex = small, colour = GOLD, font = 1,
               tracking = 0.34)

  invisible(path)
}

if (!dir.exists(file.path("man", "figures"))) {
  dir.create(file.path("man", "figures"), recursive = TRUE)
}
out <- file.path("man", "figures", "logo.png")
build_logo(out)
message("Wrote ", out, " (", file.size(out), " bytes)")
