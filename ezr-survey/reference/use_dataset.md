# Set a default dataset for the session

Registers a data frame as the session's default, so the analysis helpers
can be called without repeating `data` every time. Set it once at the
top of a script or Quarto document and then omit `data` (or pass it by
pipe).

## Usage

``` r
use_dataset(data)
```

## Arguments

- data:

  A data frame to use as the default.

## Value

`data`, invisibly (so it can sit in a pipe).

## Details

With a default set you can drop `data` entirely and name the column
positionally, the way you would in the tidyverse:

- `calc_percentage(demo_gender)` – data taken from the default;

- `podracing_survey %>% calc_percentage(demo_gender)` – explicit pipe;

- `calc_percentage(other_survey, demo_gender)` – an explicit data frame
  always wins over the default.

The helpers tell a column from a data frame by looking at the first
argument: a data frame is used as the data; anything else (a bare column
name) is taken as the first column and the data comes from the default.
Helpers that select several columns through `...` (e.g.
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md))
work the same way – `diagnose(starts_with("ratings_"))` needs no `data`.

The default applies to the analysis helpers that read a raw survey
([`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md),
...). It does **not** apply to plot/report helpers that consume an
already-summarised table. The setting lives only in the current R
session; clear it with
[`clear_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md).

## See also

[`get_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md),
[`clear_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md),
[`has_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md).

Other config:
[`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md),
[`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md),
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md),
[`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md),
[`get_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md),
[`get_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/get_order.md),
[`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md),
[`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md),
[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md),
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md),
[`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
use_dataset(podracing_survey)
calc_percentage(demo_gender)   # data taken from the default
#> # A tibble: 3 × 3
#>   demo_gender     n   pct
#>   <chr>       <int> <dbl>
#> 1 Female        399    42
#> 2 Male          525    55
#> 3 Non-binary     27     3
calc_nps(nps_value)
#> # A tibble: 1 × 8
#>       n   nps pct_detractors pct_passives pct_promoters detractors passives
#>   <int> <dbl>          <dbl>        <dbl>         <dbl>      <int>    <int>
#> 1  1000     7             25           43            32        252      426
#> # ℹ 1 more variable: promoters <int>
clear_dataset()
```
