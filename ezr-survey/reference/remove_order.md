# Remove a registered order

Remove a registered order

## Usage

``` r
remove_order(name)
```

## Arguments

- name:

  Order name.

## Value

Invisibly `TRUE`.

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
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
register_order("yesno", c("No", "Yes"))
remove_order("yesno")
```
