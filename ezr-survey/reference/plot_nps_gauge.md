# Score gauge with decision bands and a value marker

A horizontal gauge that places a single score (NPS or mean rating) onto
a banded scale, with a "you are here" marker: the NPS and quality gauges
a summary slide carries.

## Usage

``` r
plot_nps_gauge(
  score,
  scale = c("nps", "rating"),
  title = NULL,
  height = 0.5,
  label_size = NULL
)
```

## Arguments

- score:

  The score to mark (NPS on -100..100, or a mean rating on 1..5).

- scale:

  `"nps"` (default) or `"rating"`, selecting the band layout and limits.

- title:

  Optional title; a sensible default is generated from `score`.

- height:

  Bar thickness in plot units. Defaults to `0.5`.

- label_size:

  Band-label text size. `NULL` (default) matches the theme's base font
  size (11 pt).

## Value

A ggplot object.

## Details

Takes a single number (not a dataset) and places it on a coloured band
scale with a black marker, for the headline "where do we stand" slide.
`"nps"` uses a -100..100 scale banded from needs-work to excellent;
`"rating"` uses a 1..5 scale with BAD/OK/GOOD bands. Pair it with
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)
for the score.

## See also

[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md).

Other plots:
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
nps <- calc_nps(podracing_survey, nps_value)$nps
plot_nps_gauge(nps)


plot_nps_gauge(3.8, scale = "rating")
```
