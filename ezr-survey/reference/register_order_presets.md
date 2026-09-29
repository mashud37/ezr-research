# Register a set of common ordinal scales

A convenience that registers a handful of frequently used orders, linked
to sensible default variable names/prefixes, so common surveys work out
of the box. Override any of them afterwards with
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md).

## Usage

``` r
register_order_presets()
```

## Value

Invisibly the names registered.

## Details

Registers: `likert_bad_good`, `likert_agree`, `frequency`, `likelihood`
and `education_isced`.

## See also

[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md).

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
[`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
register_order_presets()
list_orders()
#> # A tibble: 5 × 4
#>   name            n_levels vars                prefixes
#>   <chr>              <int> <chr>               <chr>   
#> 1 education_isced        7 demo_edu, education edu_    
#> 2 frequency              5 NA                  NA      
#> 3 likelihood             5 satis_return        NA      
#> 4 likert_agree           5 NA                  NA      
#> 5 likert_bad_good        5 NA                  ratings_
```
