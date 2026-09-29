# Bar chart of a percentage table (auto-laid-out)

Plots the output of
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
(or
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md))
as a labelled bar chart, with a tidy auto-scaled axis
([`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md))
and the ezrsurvey theme. By default the **layout is chosen for you**:
vertical columns for a few short labels, horizontal bars for many or
long ones, with long labels wrapped, the text size stepped down as bars
multiply, and the bars ordered so the longest sits at the top (bars) or
on the left (cols).

## Usage

``` r
plot_bars(
  data,
  label = NULL,
  value = pct,
  orientation = c("auto", "cols", "bars"),
  sort = c("auto", "none", "asc", "desc"),
  wrap = NULL,
  flip = NULL,
  avg_line = FALSE,
  axis_labels = FALSE,
  unit = ezrsurvey_default("pct_axis_unit"),
  max = ezrsurvey_default("pct_axis_max"),
  fill = NULL,
  title = NULL,
  label_size = NULL
)
```

## Arguments

- data:

  A data frame with a category column and a value column.

- label:

  Category column (unquoted). If `NULL` (default), the first non-`n`,
  non-value column is used.

- value:

  Value column (unquoted). Defaults to `pct`.

- orientation:

  `"auto"` (default), `"cols"` (vertical) or `"bars"` (horizontal).
  `"auto"` picks horizontal bars when there are more than
  `bar_cols_max_items` items or a label longer than `bar_cols_max_label`
  characters (see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).

- sort:

  `"auto"` (default), `"none"`, `"asc"` or `"desc"`. `"auto"` orders
  bars by value so the longest is on top (bars) or on the left (cols),
  but leaves an intentional ordinal scale (an ordered factor, e.g. from
  a registered order) untouched.

- wrap:

  Label wrap width in characters
  ([`stringr::str_wrap()`](https://stringr.tidyverse.org/reference/str_wrap.html)).
  `NULL` (default) uses `bar_wrap_cols` / `bar_wrap_bars` for the chosen
  orientation.

- flip:

  Deprecated back-compat shortcut: `TRUE` forces `orientation = "bars"`,
  `FALSE` forces `"cols"`. `NULL` (default) defers to `orientation`.

- avg_line:

  If `TRUE`, add a reference line at the mean value. Defaults to
  `FALSE`.

- axis_labels:

  If `TRUE`, show the percentage axis; if `FALSE` (default) hide it (the
  bars carry their own data labels).

- unit:

  Axis rounding step passed to
  [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md).
  Defaults to the `pct_axis_unit` option (`25`; see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).

- max:

  Optional fixed y-axis maximum (e.g. `100`). Defaults to the
  `pct_axis_max` option (`NULL` = dynamic).

- fill:

  Bar fill colour. `NULL` (default) uses the brand primary colour when a
  brand is set (see
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)),
  else
  [pal_neutral](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md).

- title:

  Optional plot title.

- label_size:

  Data-label text size. `NULL` (default) steps down from
  `bar_label_size` as the number of bars grows (floored at
  `bar_size_min`).

## Value

A ggplot object.

## Details

Expects a summary table (from
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
and friends), not raw survey rows. The label column is auto-detected as
the first non-`n`, non-value column, so a piped percentage table just
works. The layout decisions all read from the `bar_*` options
([`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)):
`orientation = "auto"` switches to horizontal bars once there are many
or long labels, labels are wrapped to `bar_wrap_cols` / `bar_wrap_bars`,
the data-label size steps down with the bar count, and `sort = "auto"`
puts the longest bar at the top (bars) or on the left (cols) – unless
the label column is an ordered factor (a registered or explicit order),
which is preserved. The axis ceiling is chosen by
[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)
/ the `pct_axis_*` options so data labels never collide with the panel
top, and the `%` axis is hidden unless `axis_labels = TRUE`. Add
decision guidance with
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md).

Bars are drawn to a constant thickness regardless of how many there are
(`bar_width` / `bar_ref_items`, see
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)),
so a three-answer chart and a ten-answer chart look like they belong in
the same deck instead of the first one's bars turning into slabs.

## See also

[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md),
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md).

Other plots:
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
# auto layout: few short labels -> vertical columns, largest on the left
calc_percentage(podracing_survey, demo_gender) %>% plot_bars()


# many long labels -> horizontal bars, wrapped, largest on top
calc_percentage(podracing_survey, fav_driver) %>% plot_bars()


# an ordinal scale keeps its order; force horizontal with orientation
calc_percentage(podracing_survey, demo_edu) %>%
  plot_bars(orientation = "bars")
```
