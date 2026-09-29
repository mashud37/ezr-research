# NPS group fill scale

Manual fill scale mapping the NPS-group coding (`"-1" / "0" / "1"`) onto
the
[pal_nps](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
palette.

## Usage

``` r
scale_fill_nps(...)
```

## Arguments

- ...:

  Passed to
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2 scale.

## Details

Maps the NPS-group coding from
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md)
(`"-1"` detractor, `"0"` passive, `"1"` promoter) onto the
[pal_nps](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
red/amber/green palette, so the colours carry their usual meaning. Used
by
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md).

## See also

[pal_nps](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md).

Other themes:
[`pal_rating`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[`scale_fill_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md),
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md),
[`theme_transparent()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_transparent.md)

## Examples

``` r
df <- data.frame(score = 0:2, pct = c(20, 30, 50), group = c(-1, 0, 1))
ggplot(df, aes(score, pct, fill = factor(group))) +
  geom_col() +
  scale_fill_nps()
```
