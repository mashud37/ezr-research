# Summarise a numeric question (mean / median / sd)

The numeric counterpart to
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md):
a one-liner for the `summarise(mean, median, sd)` blocks used on age and
other continuous variables, with optional grouping.

## Usage

``` r
calc_summary(data = NULL, column, by = NULL, na_rm = TRUE, weights = NULL)
```

## Arguments

- data:

  A data frame.

- column:

  Numeric column to summarise (unquoted).

- by:

  Optional grouping column(s); see
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

- na_rm:

  Drop `NA` before summarising. Defaults to `TRUE`.

- weights:

  Survey weighting: `NULL` (default) uses the session scheme from
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  if set; `FALSE` forces unweighted; or pass an ad-hoc scheme. When
  weighting is active the `mean`, `median` and `sd` become their
  weighted versions (`n` stays the unweighted base).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with `n`
(non-missing count), `mean`, `median` and `sd`, one row per group when
`by` is supplied.

## Details

The column is passed through
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md)
first, so a text age column like `"25 years"` still summarises. `n`
counts non-missing values (after that coercion). When a weighting scheme
is active the statistics are weighted (and missing values are dropped);
`n` remains the unweighted respondent count. For a measure of how
precise the `mean` is, pair this with
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
or
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md).

## See also

[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
for categorical variables,
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
for precision.

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
calc_summary(podracing_survey, demo_age)
#> # A tibble: 1 × 4
#>       n  mean median    sd
#>   <int> <dbl>  <dbl> <dbl>
#> 1  1000  32.6     32  11.2

calc_summary(podracing_survey, demo_age, by = region)
#> # A tibble: 5 × 5
#>   region            n  mean median    sd
#>   <chr>         <int> <dbl>  <dbl> <dbl>
#> 1 Asia             59  31.9   32    11.0
#> 2 Europe          314  32.9   32    11.0
#> 3 Latin America    82  30.6   31    10.4
#> 4 North America   503  33.2   33    11.5
#> 5 Oceania          42  28.6   27.5  10.2
```
