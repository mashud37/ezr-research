# Build an importance / performance model

Combines driver **importance** (against `outcome`) with feature
**performance** (mean rating) into the tidy table consumed by
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md).
Worded rating columns are recoded to 1-5 automatically.

## Usage

``` r
ipm_model(
  data = NULL,
  outcome,
  rating_prefix,
  method = c("rwa", "forest", "correlation"),
  recode = TRUE,
  likert_levels = c("Very bad", "Bad", "Ok", "Good", "Very good")
)
```

## Arguments

- data:

  A data frame.

- outcome:

  The outcome column (unquoted), e.g. `nps_value`.

- rating_prefix:

  Column-name prefix identifying the rating block, e.g. `"ratings_"`.

- method:

  How to measure importance, passed to
  [`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md).
  Defaults to `"rwa"`.

- recode:

  If `TRUE` (default), character rating columns are mapped to 1-5 with
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md);
  numeric columns are left as-is.

- likert_levels:

  Scale wordings passed to
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
  when recoding.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`feature`, `importance`, `performance` and `perf_class` (the performance
band as a 1-5 factor, from its integer part so a 3.57 mean sits in band
3, used for colouring).

## Details

An importance/performance model answers two questions per feature at
once: *how much does it drive the outcome* (importance, via
[`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md))
and *how well are we doing on it* (performance, the mean 1–5 rating).
Plotting one against the other
([`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md))
reveals priorities: high-importance, low-performance features are where
to invest. Worded rating columns are mapped to 1–5 with
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
automatically (`recode = TRUE`); the prefix is stripped from feature
names; and `perf_class` buckets performance into a 1–5 factor by its
integer part (a 3.57 mean is band 3, not 4) for colouring. Importance
comes from
[`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md),
so `method` chooses between relative weights (the default, requiring the
suggested `rwa` package), a random forest and a plain correlation.

## See also

[`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`compare_values()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/compare_values.md).

Other modelling:
[`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md),
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)

## Examples

``` r
ipm_model(podracing_survey, nps_value, "ratings_")
#> Parsing `nps_value` as a non-binary variable.
#> Applying multiple regression to calculate relative weights...
#> # A tibble: 6 × 4
#>   feature    importance performance perf_class
#>   <chr>           <dbl>       <dbl> <fct>     
#> 1 value           24.9         2.86 2         
#> 2 atmosphere      23.8         3.57 3         
#> 3 speed           18.0         3.48 3         
#> 4 safety          14.1         2.88 2         
#> 5 venue           12.2         3.08 3         
#> 6 commentary       6.99        2.58 2         
```
