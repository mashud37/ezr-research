# Brand colour palette

Returns the organisation's accent colours set by
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
(or the `brand_colors` option), ready for manual scales or direct use.
Without a brand, it falls back to
[pal_sequential_blue](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
so it always returns something usable.

## Usage

``` r
pal_brand(n = NULL)
```

## Arguments

- n:

  Number of colours wanted. `NULL` (default) returns the full accent
  vector as-is; when `n` exceeds the available colours the palette is
  interpolated with
  [`grDevices::colorRampPalette()`](https://rdrr.io/r/grDevices/colorRamp.html).

## Value

A character vector of hex colours.

## Details

Only the *categorical* brand accents live here. The semantic palettes
([pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[pal_nps](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md))
keep their red-amber-green vocabulary regardless of brand – recolouring
"bad to good" with corporate accents would destroy the meaning the
colours carry.

## See also

[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md).

Other brand:
[`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md),
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md),
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)

## Examples

``` r
pal_brand()      # sequential blue until a brand is set
#> [1] "#8FE2FF" "#43CEFF" "#00B0F0" "#0070C0"
pal_brand(2)
#> [1] "#8FE2FF" "#43CEFF"
```
