# Mark a single value on a plot

Adds a reference line (and optional label) at a single value – the "you
are here" marker used on the NPS and quality gauges.

## Usage

``` r
mark_value(
  plot,
  value,
  axis = c("x", "y"),
  colour = "black",
  linewidth = 1,
  label = NULL,
  ...
)
```

## Arguments

- plot:

  A ggplot object.

- value:

  Numeric position of the marker.

- axis:

  Axis the value is on: `"x"` (default, draws a vertical line) or `"y"`
  (horizontal line).

- colour, linewidth:

  Line appearance.

- label:

  Optional text label drawn at the marker.

- ...:

  Passed to
  [`ggplot2::annotate()`](https://ggplot2.tidyverse.org/reference/annotate.html)
  for the label; overrides the default justification, which keeps the
  label inside the panel next to the marker line.

## Value

The plot with the marker added.

## See also

Other decisions:
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md),
[`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)

## Examples

``` r
# a target line across the percentage axis of a bar chart
calc_percentage(podracing_survey, demo_gender) %>%
  plot_bars() %>%
  mark_value(20, axis = "y", label = "Target 20%")
```
