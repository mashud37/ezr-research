# Add region (and subregion) columns from a country column

Convenience wrapper that appends a `region` column (and optionally a
`subregion`) to a data frame by looking up an existing country column
with
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md).

## Usage

``` r
add_region(
  data = NULL,
  country,
  region_to = "region",
  subregion = FALSE,
  quiet = FALSE
)
```

## Arguments

- data:

  A data frame.

- country:

  The country column (unquoted).

- region_to:

  Name of the region column to add. Defaults to `"region"`.

- subregion:

  If `TRUE`, also add a `subregion` column. Defaults to `FALSE`.

- quiet:

  Passed to
  [`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md).

## Value

`data` with the new column(s) added.

## Details

This is the data-frame-friendly form of
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md):
point it at an existing country column and it appends a `region` column
(named via `region_to`) and, optionally, a `subregion`. Handy right
after
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md)
to enrich raw exports before grouping by region. The lookup, matching
and unmatched-country warning behave exactly as in
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md).

## See also

[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[country_region](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md).

Other recode:
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
df <- tibble::tibble(demo_country = c("Germany", "Japan", "Brazil"))
add_region(df, demo_country, subregion = TRUE)
#> # A tibble: 3 × 3
#>   demo_country region        subregion     
#>   <chr>        <chr>         <chr>         
#> 1 Germany      Europe        Western Europe
#> 2 Japan        Asia          East Asia     
#> 3 Brazil       South America South America 
```
