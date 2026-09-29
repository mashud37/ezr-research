# Apply a registered order to a vector

Turns a vector into an ordered factor using a registered order, selected
either by order `name` or by looking up the order linked to a variable
name.

## Usage

``` r
apply_order(x, name = NULL, var = NULL)
```

## Arguments

- x:

  A vector.

- name:

  Order name (see
  [`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)).
  Takes precedence over `var`.

- var:

  A variable name to look up via
  [`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md).

## Value

A factor with the registered levels, or `x` unchanged if no order is
found.

## See also

[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md),
[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md).

Other config:
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
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
register_order("size", c("S", "M", "L"))
apply_order(c("L", "S", "M"), name = "size")
#> [1] L S M
#> Levels: S < M < L
remove_order("size")
```
