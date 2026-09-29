# Transparent-background theme fragment

A small
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
fragment that makes the plot, panel and legend backgrounds transparent.
Add it to any theme for slide-friendly exports; the `transparent`
argument of
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
applies it for you.

## Usage

``` r
theme_transparent()
```

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## See also

Other themes:
[`pal_rating`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[`scale_fill_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_fill_nps.md),
[`scale_fill_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md),
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)

## Examples

``` r
p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
p + theme_transparent()
```
