# Draws the package logo: man/figures/logo.png
#
# A pointy-top hexagon, the shape the R community uses for package stickers, in
# the navy and gold the bundled deck template already carries. Inside it a
# questionnaire with a face, drawn from a character grid the way the pepa and
# kopi mascots are, so the family looks related. Base graphics only, so this
# needs nothing the package does not already depend on.
#
# Run from the package root: Rscript data-raw/make_logo.R

NAVY <- "#12314E"
GOLD <- "#C9A227"
PAPER <- "#FFFFFF"
STEEL <- "#8FA3B8"

# One character per pixel, rows top to bottom.
#   .  nothing   o  board   w  paper   E  eye   m  mouth   g  a filled answer
MASCOT <- c(
  ".....oooooo.....",
  "...oooooooooo...",
  "...owwwwwwwwo...",
  "...owEwwwwEwo...",
  "...owwwwwwwwo...",
  "...owmwwwwmwo...",
  "...owwmmmmwwo...",
  "...owwwwwwwwo...",
  "...ogggggggwo...",
  "...owwwwwwwwo...",
  "...oggggwwwwo...",
  "...owwwwwwwwo...",
  "...oggggggwwo...",
  "...oooooooooo...",
  "....o......o....",
  "...oo......oo..."
)

INK <- c(o = STEEL, w = PAPER, E = NAVY, m = NAVY, g = GOLD)

hexagon <- function(x, y, radius) {
  angles <- (seq(0, 5) * 60 + 90) * pi / 180
  list(x = x + radius * cos(angles), y = y + radius * sin(angles))
}

draw_grid <- function(grid, left, bottom, cell) {
  rows <- length(grid)
  for (r in seq_len(rows)) {
    chars <- strsplit(grid[[r]], "")[[1]]
    for (c in seq_along(chars)) {
      if (!chars[[c]] %in% names(INK)) next
      x <- left + (c - 1) * cell
      y <- bottom + (rows - r) * cell
      rect(x, y, x + cell, y + cell, col = INK[[chars[[c]]]], border = NA)
    }
  }
}

build_logo <- function(path, px_wide = 480) {
  radius <- 1
  wide <- radius * sqrt(3)
  px_tall <- round(px_wide * 2 * radius / wide)

  grDevices::png(path, width = px_wide, height = px_tall, bg = "transparent",
                 res = 300)
  on.exit(grDevices::dev.off(), add = TRUE)
  par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(xlim = c(-wide / 2, wide / 2), ylim = c(-radius, radius),
              asp = 1)

  outer <- hexagon(0, 0, radius)
  polygon(outer$x, outer$y, col = GOLD, border = NA)
  inner <- hexagon(0, 0, radius * 0.94)
  polygon(inner$x, inner$y, col = NAVY, border = NA)

  # The hexagon tapers above y = 0.5, so the grid has to clear that point:
  # at height y its half-width is sqrt(3) * (1 - y).
  cell <- wide / 28
  columns <- nchar(MASCOT[[1]])
  draw_grid(MASCOT,
            left = -columns * cell / 2,
            bottom = -0.33,
            cell = cell)

  text(0, -0.60, "ezrsurvey", col = PAPER, cex = 0.82, font = 2,
       family = "sans")

  invisible(path)
}

if (!dir.exists(file.path("man", "figures"))) {
  dir.create(file.path("man", "figures"), recursive = TRUE)
}
out <- file.path("man", "figures", "logo.png")
build_logo(out)
message("Wrote ", out, " (", file.size(out), " bytes)")
