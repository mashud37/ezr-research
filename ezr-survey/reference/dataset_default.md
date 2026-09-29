# Get, check or clear the default dataset

Companions to
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md)
for inspecting and resetting the session's default dataset.

## Usage

``` r
get_dataset()

has_dataset()

clear_dataset()

dataset_vars()
```

## Value

`get_dataset()` returns the default data frame (error if none is set);
`has_dataset()` returns a logical; `clear_dataset()` returns `TRUE`
invisibly; `dataset_vars()` returns a character vector of column names.

## Details

`has_dataset()` is the safe way to check before calling `get_dataset()`,
which errors when nothing is set. `clear_dataset()` removes the default
so that subsequent calls require an explicit `data` again – useful at
the end of a script or between analyses of different datasets.

## See also

[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md).

Other config:
[`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md),
[`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md),
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md),
[`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md),
[`get_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/get_order.md),
[`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md),
[`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md),
[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md),
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md),
[`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
has_dataset()
#> [1] FALSE

use_dataset(podracing_survey)
has_dataset()
#> [1] TRUE

nrow(get_dataset())
#> [1] 1000

clear_dataset()
```
