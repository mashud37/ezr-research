# Brand fill and colour scales

Discrete ggplot2 scales using the brand accent palette from
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md).
`scale_color_brand()` is an alias of `scale_colour_brand()`.

## Usage

``` r
scale_fill_brand(...)

scale_colour_brand(...)

scale_color_brand(...)
```

## Arguments

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 scale.

## Details

The palette function interpolates when a plot needs more colours than
the brand defines, so the scale never runs out. Without a brand set, the
scales fall back to the
[pal_sequential_blue](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
defaults via
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md).

## See also

[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md).

Other brand:
[`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md),
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md),
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)

## Examples

``` r
df <- calc_percentage(podracing_survey, demo_gender)
ggplot(df, aes(demo_gender, pct, fill = demo_gender)) +
  geom_col() +
  scale_fill_brand()
```
