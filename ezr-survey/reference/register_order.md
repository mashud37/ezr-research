# Register a reusable ordinal level order

Survey scales (education, Likert, frequency, ...) have a natural order
that is tedious to retype as `levels = c(...)` every time. Register an
order once, link it to the variable names and/or column prefixes it
applies to, and the tabulating helpers (e.g.
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md))
will look it up and apply it automatically. Persist your orders in a
profile with
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md).

## Usage

``` r
register_order(name, levels, vars = NULL, prefixes = NULL, overwrite = TRUE)
```

## Arguments

- name:

  Short name for the order (e.g. `"education"`).

- levels:

  Character vector of the levels in ascending order.

- vars:

  Optional exact column names this order applies to (e.g. `"demo_edu"`).

- prefixes:

  Optional column-name prefixes this order applies to (e.g. `"edu_"`). A
  variable matches if its name starts with any prefix.

- overwrite:

  Overwrite an existing order of the same name. Default `TRUE`.

## Value

Invisibly the order `name`.

## Details

An order links a set of `levels` to the columns it applies to, by exact
name (`vars`) and/or by prefix (`prefixes`). Once registered,
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
and
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
look it up automatically (via
[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md))
whenever you don't pass an explicit `levels`/`sort`, so a question
always comes out in the right order without retyping it. Register
interactively for the session, or store orders in a profile with
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md)
so they load every session.

## See also

[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md),
[`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md),
[`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md),
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md).

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
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md),
[`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
register_order(
  "education",
  levels = c("Primary or less", "Lower secondary", "Upper secondary",
             "Short-cycle tertiary", "Bachelor or equivalent",
             "Master or equivalent", "Doctoral or equivalent"),
  vars = "demo_edu"
)
calc_percentage(podracing_survey, demo_edu)   # rows now in education order
#> # A tibble: 7 × 3
#>   demo_edu                   n   pct
#>   <ord>                  <int> <dbl>
#> 1 Primary or less           42     4
#> 2 Lower secondary          111    11
#> 3 Upper secondary          295    30
#> 4 Short-cycle tertiary     123    13
#> 5 Bachelor or equivalent   244    25
#> 6 Master or equivalent     122    13
#> 7 Doctoral or equivalent    35     4
remove_order("education")
```
