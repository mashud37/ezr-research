# Treemap of selected quotes

A treemap where each tile is a comment sized by length – the quote slide
of a survey deck. Requires the suggested `treemapify` package.

## Usage

``` r
plot_quotes_tree(data, label = comment, area = length, colour = "black")
```

## Arguments

- data:

  A data frame of quotes, e.g. from
  [`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md).

- label:

  Text column (unquoted). Defaults to `comment`.

- area:

  Tile-size column (unquoted). Defaults to `length`.

- colour:

  Tile border colour. Defaults to `"black"`.

## Value

A ggplot object.

## Details

Lays selected verbatims out as a treemap, each tile sized by comment
length, so a slide can show real customer voice at a glance. Pair it
with
[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md)
or
[`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md),
which produce the `comment`/`length` columns it expects. Requires the
suggested `treemapify` package.

## See also

[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md),
[`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md).

Other plots:
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
sample_comments(podracing_survey, nps_com, show_com, n = 5) %>%
  plot_quotes_tree()
```
