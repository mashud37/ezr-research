# Generational-cohort definitions

Returns the birth-year boundaries for a named generational scheme, for
use by
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md).
The default `"pew"` scheme follows the widely cited Pew Research Center
cohort definitions.

## Usage

``` r
generation_scheme(scheme = c("pew"))
```

## Arguments

- scheme:

  Scheme name. Currently `"pew"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`label`, `from` (first birth year) and `to` (last birth year; `Inf` for
the open-ended youngest cohort).

## Details

The `"pew"` scheme uses the Pew Research Center boundaries: Silent
(1928–45), Baby Boomer (1946–64), Gen X (1965–80), Millennial (1981–96),
Gen Z (1997–2012) and Gen Alpha (2013+). To use different cut-offs,
build your own tibble with `from` and `label` columns and pass it to
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md)'s
`scheme` argument.

## See also

[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
generation_scheme("pew")
#> # A tibble: 6 × 3
#>   label        from    to
#>   <chr>       <dbl> <dbl>
#> 1 Silent       1928  1945
#> 2 Baby Boomer  1946  1964
#> 3 Gen X        1965  1980
#> 4 Millennial   1981  1996
#> 5 Gen Z        1997  2012
#> 6 Gen Alpha    2013   Inf
```
