# Load ezrsurvey defaults from a YAML profile

Reads a YAML file of `option: value` pairs and applies them with
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md).
Called automatically when the package loads (over the standard
[`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md));
call it manually to load a specific file. Requires the suggested `yaml`
package; without it, the function is a no-op.

## Usage

``` r
load_ezrsurvey_profile(path = NULL, quiet = TRUE)
```

## Arguments

- path:

  Profile path(s). If `NULL` (default), the standard locations are tried
  in order (later files override earlier ones).

- quiet:

  If `TRUE` (default), load silently; if `FALSE`, message which file(s)
  were loaded.

## Value

Invisibly `TRUE` if any profile was applied, else `FALSE`.

## See also

[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)
to create a template.

Other config:
[`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md),
[`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md),
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md),
[`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md),
[`get_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md),
[`get_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/get_order.md),
[`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md),
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
if (FALSE) { # \dontrun{
load_ezrsurvey_profile("~/.ezrsurvey.yml", quiet = FALSE)
} # }
```
