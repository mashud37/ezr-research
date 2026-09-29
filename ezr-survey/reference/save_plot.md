# Quick-save a plot to PNG, SVG or PDF

A thin, pipe-friendly wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
that picks the device from the file extension and uses
presentation-friendly defaults (transparent background, generous size).
Returns the plot invisibly, so it drops into a pipeline without breaking
it.

## Usage

``` r
save_plot(
  plot,
  path = NULL,
  width = 8,
  height = 4.5,
  dpi = 300,
  bg = "transparent",
  ...
)
```

## Arguments

- plot:

  A ggplot object.

- path:

  Output path; the extension sets the format (`.png`, `.svg`, `.pdf`,
  `.jpg`/`.jpeg`, `.tiff`). `NULL` (default) writes `plot.png`. A bare
  file name lands in `ezrsurvey-outputs/` (created on demand); a path
  naming a directory (`"./x.png"`, `"charts/x.png"`, anything absolute)
  is used exactly as given. See the `output_dir` option.

- width, height:

  Size in inches. Default `8 x 4.5`.

- dpi:

  Raster resolution for PNG/JPG/TIFF. Default `300`.

- bg:

  Background fill. Default `"transparent"` (matches the ezrsurvey
  themes); use `"white"` for a solid background.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The `plot`, invisibly.

## Details

The device is chosen from the file extension, and the plot is returned
invisibly so the call slots into a pipeline without breaking it
(`p %>% save_plot("p.png") %>% print()`). Defaults suit slides: a
transparent background (matching the ezrsurvey themes) and a generous
size; pass `bg = "white"` for a solid background. SVG output needs the
suggested `svglite` package.

## See also

[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md).

Other save:
[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md)

## Examples

``` r
p <- plot_bars(calc_percentage(podracing_survey, demo_gender))
tmp <- tempfile(fileext = ".png")
save_plot(p, tmp)
file.exists(tmp)
#> [1] TRUE
```
