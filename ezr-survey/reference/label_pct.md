# Percent label formatter

Returns a function that turns numbers into percent strings, e.g. `42`
becomes `"42%"`. The input is assumed to already be on a 0-100 scale (as
produced by
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)),
not a 0-1 proportion.

## Usage

``` r
label_pct(digits = 0, suffix = "%")
```

## Arguments

- digits:

  Number of decimal places to keep. Defaults to `0`.

- suffix:

  String appended after the number. Defaults to `"%"`.

## Value

A function suitable for the `labels` argument of a ggplot2 scale or for
use with
[geom_text()](https://ggplot2.tidyverse.org/reference/geom_text.html).

## Details

`label_pct()` returns a *function* (a closure), not formatted strings –
this is the form ggplot2 scales expect for their `labels` argument. The
number is rounded to `digits` decimal places with
[`formatC()`](https://rdrr.io/r/base/formatc.html) and `suffix`
appended. Because the input is assumed to be on a 0–100 scale,
`label_pct()(42)` is `"42%"`, not `"4200%"`.

## See also

[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md).

Other scales:
[`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md),
[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md)

## Examples

``` r
f <- label_pct()
f(c(0, 33.4, 100))
#> [1] "0%"   "33%"  "100%"

label_pct(1)(33.45)
#> [1] "33.5%"
```
