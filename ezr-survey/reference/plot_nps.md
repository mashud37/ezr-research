# NPS distribution slide (0-10 scale with group labels)

The canonical Net Promoter Score chart: the full 0-10 recommendation
distribution as labelled bars coloured by NPS group, with the detractor
/ passive / promoter shares called out in coloured boxes across the top
and the overall NPS in the title: the NPS slide of a survey deck, in one
call.

## Usage

``` r
plot_nps(data = NULL, value, title = NULL)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- value:

  The 0-10 recommendation column (unquoted). Text such as `"8 - likely"`
  is salvaged with
  [`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md).

- title:

  Optional title; defaults to `"Net Promoter Score of: <score>"`.

## Value

A ggplot object.

## Details

Unlike
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md)
(which takes a single score), this reads the raw 0–10 column and draws
the full distribution: one labelled bar per score, coloured
red/amber/green by NPS group, with the detractor/passive/promoter shares
called out across the top and the overall score in the title. It is the
detailed companion slide to the gauge.

## See also

[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md).

Other plots:
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
plot_nps(podracing_survey, nps_value)
```
