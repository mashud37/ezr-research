# Move a band specification onto another scale

The band presets are written on the scales survey work uses most: 1-5
for a rating, 0-10 for the Net Promoter answer, -100 to 100 for the
score. Plenty of real questionnaires do not use those. Satisfaction is
often collected on 0-100, and a seven-point agreement scale is common.
`rescale_bands()` stretches a band specification onto the scale the
chart is actually drawn on, so the thresholds can stay where they are
instead of the data being divided to meet them.

## Usage

``` r
rescale_bands(bands, to, from = NULL)
```

## Arguments

- bands:

  A band specification: one of
  [`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  and friends, or any data frame with `from` and `to` columns.

- to:

  Length-2 numeric: the scale the chart uses, as `c(min, max)`.

- from:

  Length-2 numeric: the scale `bands` is written on. Read from the band
  edges themselves when omitted, which is what you want for the presets.

## Value

`bands` with `from` and `to` moved onto the new scale. Labels and
colours are untouched.

## Details

The mapping is linear and proportional: a band covering the top fifth of
its own scale covers the top fifth of the new one. Rescale rather than
divide the data, so the axis a reader sees is still the scale the
question was asked on.

## See also

Other decisions:
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md),
[`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md),
[`mark_value()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/mark_value.md)

## Examples

``` r
# satisfaction collected 0-100, thresholds still where they belong
bands_rating_3() %>% rescale_bands(to = c(0, 100))
#>   label from  to  colour
#> 1   BAD    0  50 #FF3300
#> 2    OK   50  75 #FFCB3E
#> 3  GOOD   75 100 #86A33B

# a seven-point agreement scale
bands_rating_3() %>% rescale_bands(to = c(1, 7))
#>   label from  to  colour
#> 1   BAD  1.0 4.0 #FF3300
#> 2    OK  4.0 5.5 #FFCB3E
#> 3  GOOD  5.5 7.0 #86A33B
```
