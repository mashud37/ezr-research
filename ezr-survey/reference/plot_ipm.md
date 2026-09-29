# Importance / performance matrix

Plots an
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
table as a scatter of feature performance (x) vs. importance (y),
coloured by performance band, with decision bands across the top: the
importance / performance slide of a survey deck, in one call.

## Usage

``` r
plot_ipm(model, title = NULL, repel = TRUE, bands = bands_rating_3())
```

## Arguments

- model:

  An
  [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
  output (`feature`, `importance`, `performance`, `perf_class`).

- title:

  Optional title; defaults to the average performance.

- repel:

  Use `ggrepel` for non-overlapping labels when available. Defaults to
  `TRUE`.

- bands:

  Decision-band spec drawn across the top and used to colour the points.
  Defaults to
  [`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  (BAD 1-3, OK 3-4, GOOD 4-5).

## Value

A ggplot object.

## Details

Each feature is a point: performance on the x-axis (mean 1–5 rating,
with a reference line at the average) and importance on the y-axis
(relative weight, as a percentage). Each point takes the colour of the
decision band it falls in, so a feature averaging 2.4 is red because it
sits in the BAD band – the point and the band behind it can never
disagree. Read it by quadrant – high-importance, low-performance
features (upper left) are the priorities to fix, while high-importance,
high-performance features (upper right) are strengths to protect. Feed
it an
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
table; uses `ggrepel` for non-overlapping labels when available.

## See also

[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`compare_values()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/compare_values.md).

Other plots:
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
ipm_model(podracing_survey, nps_value, "ratings_") %>% plot_ipm()
#> Parsing `nps_value` as a non-binary variable.
#> Applying multiple regression to calculate relative weights...
```
