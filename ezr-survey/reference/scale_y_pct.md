# Continuous y-scale capped at a nice maximum with optional percent labels

A thin wrapper around
[`ggplot2::scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
that sets the upper limit with
[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)
and, by default, formats the axis as percentages. Designed for the
percentage bar charts produced by
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

## Usage

``` r
scale_y_pct(values = NULL, unit = 25, pad = 0, max = NULL, labels = TRUE, ...)
```

## Arguments

- values:

  Numeric vector used to determine the axis ceiling, typically the
  column being plotted. If `NULL` (default) the limit is left to ggplot2
  and only the label formatting is applied.

- unit, pad:

  Passed to
  [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md).

- max:

  Optional fixed upper limit. If supplied (e.g. `100`), it overrides the
  dynamic
  [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)
  ceiling. Defaults to `NULL`.

- labels:

  One of:

  - `TRUE` (default) – format breaks as `"42%"`.

  - `FALSE` – hide axis labels entirely (`labels = NULL`).

  - a function – used directly as the `labels` argument.

- ...:

  Further arguments passed to
  [`ggplot2::scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html).

## Value

A ggplot2 scale you can add to a plot with `+`.

## Details

The upper limit is chosen in one of three ways, in order of precedence:
a fixed `max` if you supply one; otherwise
[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)
of `values`; otherwise left to ggplot2. Labels default to whole-percent
strings via
[`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md).
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
calls this for you, reading its `unit` and `max` from the
`pct_axis_unit` / `pct_axis_max` options (see
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)),
so you rarely add it by hand – but it is exported for custom charts.

## See also

[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md),
[`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md),
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md).

Other scales:
[`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md),
[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)

## Examples

``` r
df <- calc_percentage(podracing_survey, demo_gender)
ggplot(df, aes(demo_gender, pct)) +
  geom_col() +
  scale_y_pct(df$pct)            # axis capped at a tidy multiple, "%" labels
```
