# Rating colour and fill scales

Manual ggplot2 scales mapping a 1-5 rating (as a factor or its character
codes `"1"`..`"5"`) onto the
[pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
red-amber-green palette.

## Usage

``` r
scale_fill_rating(distinct = FALSE, ...)

scale_colour_rating(distinct = FALSE, ...)

scale_color_rating(distinct = FALSE, ...)
```

## Arguments

- distinct:

  If `TRUE`, use a fully distinct 5-colour ramp where each point has its
  own shade; if `FALSE` (default) use
  [pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
  where 1 and 2 share red and 4 and 5 share green. The distinct ramp
  suits stacked bars, where neighbouring segments need to be told apart.

- ...:

  Passed to
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  /
  [`ggplot2::scale_colour_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2 scale.

## Details

Maps the rating codes `"1"`..`"5"` onto
[pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
which uses the
[`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
thresholds (1-2 bad, 3 ok, 4-5 good). Set `distinct = TRUE` for a fully
distinct 5-colour ramp, which reads better on stacked bars where
adjacent segments must be separable. `scale_color_rating()` is an alias
of `scale_colour_rating()`.

## See also

[pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[`scale_fill_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_fill_nps.md).

Other themes:
[`pal_rating`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[`scale_fill_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_fill_nps.md),
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md),
[`theme_transparent()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_transparent.md)

## Examples

``` r
df <- data.frame(feature = c("a", "b"), pct = c(60, 40), rating = c(4, 2))
ggplot(df, aes(feature, pct, fill = factor(rating))) +
  geom_col() +
  scale_fill_rating()
```
