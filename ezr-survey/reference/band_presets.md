# Built-in decision-band presets

Ready-made band specifications for
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md).

## Usage

``` r
bands_rating_3(from = NULL, to = NULL)

bands_rating_5(from = NULL, to = NULL)

bands_nps(from = NULL, to = NULL)

bands_nps_score(from = NULL, to = NULL)
```

## Arguments

- from, to:

  Optional axis limits. A band reaching past them is trimmed and a band
  entirely outside them is dropped, so a preset can be reused on a chart
  that shows only part of the scale.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`from`, `to`, `label` and `colour`.

## Details

- `bands_rating_3()` – BAD / OK / GOOD over a 1-5 rating axis.

- `bands_rating_5()` – per-point labels (1 Very bad .. 5 Very good) over
  1-5.

- `bands_nps()` – Detractor / Passive / Promoter over a 0-10 answer
  axis.

- `bands_nps_score()` – Needs work / Good / Great / Excellent over a
  -100..100 Net Promoter Score axis (the scale a headline NPS sits on,
  not the 0-10 answers it is computed from).

Pass `from` / `to` when the chart's panel is narrower than the full
scale. Plotting a 2-5 range with the untrimmed `bands_rating_3()` would
open the BAD band at 1, off the left edge, and stretch the panel to
reach it.

## See also

Other decisions:
[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md),
[`mark_value()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/mark_value.md),
[`rescale_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rescale_bands.md)

## Examples

``` r
bands_rating_3()
#> # A tibble: 3 × 4
#>   label  from    to colour 
#>   <chr> <dbl> <dbl> <chr>  
#> 1 BAD       1     3 #FF3300
#> 2 OK        3     4 #FFCB3E
#> 3 GOOD      4     5 #86A33B

# only the part of the scale a 2-5 panel actually shows
bands_rating_3(from = 2)
#> # A tibble: 3 × 4
#>   label  from    to colour 
#>   <chr> <dbl> <dbl> <chr>  
#> 1 BAD       2     3 #FF3300
#> 2 OK        3     4 #FFCB3E
#> 3 GOOD      4     5 #86A33B

bands_nps_score()
#> # A tibble: 4 × 4
#>   label       from    to colour 
#>   <chr>      <dbl> <dbl> <chr>  
#> 1 NEEDS WORK  -100     0 #FF3300
#> 2 GOOD           0    30 #FFCB3E
#> 3 GREAT         30    70 #A7C23D
#> 4 EXCELLENT     70   100 #86A33B
```
