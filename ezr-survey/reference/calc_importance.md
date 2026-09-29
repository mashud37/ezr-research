# Driver importance

Ranks how much each predictor drives an outcome such as the NPS rating,
as importance scores summing to 100. Relative weights analysis is the
default; a random forest and a plain correlation are available as
alternatives.

## Usage

``` r
calc_importance(
  data = NULL,
  outcome,
  predictors,
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

- predictors:

  The predictor columns, using tidyselect (e.g.
  `starts_with("ratings_")`).

- method:

  How to measure importance. `"rwa"` (default) is relative weights
  analysis via
  [`rwa::rwa()`](https://martinctc.github.io/rwa/reference/rwa.html);
  `"forest"` is random-forest permutation importance via
  [`randomForest::randomForest()`](https://rdrr.io/pkg/randomForest/man/randomForest.html);
  `"correlation"` is the absolute correlation with the outcome. See
  Details.

- recode:

  If `TRUE` (default), character predictor columns are mapped to 1-5
  with
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md);
  numeric columns are left as-is.

- likert_levels:

  Scale wordings passed to
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
  when recoding.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`feature` and `importance`, the latter rescaled to sum to 100 whichever
`method` produced it, strongest driver first.

## Details

All three methods answer the same question and are scaled the same way,
so each feature's `importance` reads as "this feature accounts for X% of
what drives the outcome" and any of them can be fed to
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md).
They differ in what they can see:

- `"rwa"`, relative weights analysis (Johnson's epsilon), shares out the
  linear model's explained variance between correlated predictors, which
  ordinary regression coefficients handle poorly. This is the default
  because rating batteries are almost always heavily correlated.

- `"forest"` grows a random forest and measures how much prediction
  error rises when each predictor is permuted, so it picks up non-linear
  effects and interactions that relative weights cannot. It is the
  useful cross-check: if a feature ranks high here and low under
  `"rwa"`, its effect is not linear. Being a random method, it moves a
  little between runs; call
  [`set.seed()`](https://rdrr.io/r/base/Random.html) first for a figure
  you intend to publish.

- `"correlation"` is the crude one, ignoring the other predictors
  entirely, so correlated features double-count. Its merit is that it
  needs no suggested package and cannot fail to converge, which makes it
  a reasonable sanity check on the other two.

Only complete cases are used. Worded rating columns are recoded to 1-5
automatically (`recode = TRUE`). Negative importances (which permutation
importance can produce for a predictor that is pure noise) are floored
at zero before rescaling. Most users call
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
which pairs this with performance for the importance/performance matrix.

## See also

[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md).

Other modelling:
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)

## Examples

``` r
calc_importance(podracing_survey, nps_value, starts_with("ratings_"))
#> Parsing `nps_value` as a non-binary variable.
#> Applying multiple regression to calculate relative weights...
#> # A tibble: 6 × 2
#>   feature            importance
#>   <chr>                   <dbl>
#> 1 ratings_value           24.9 
#> 2 ratings_atmosphere      23.8 
#> 3 ratings_speed           18.0 
#> 4 ratings_safety          14.1 
#> 5 ratings_venue           12.2 
#> 6 ratings_commentary       6.99

# a cross-check that can see non-linear effects
set.seed(1)
calc_importance(podracing_survey, nps_value, starts_with("ratings_"),
                method = "forest")
#> # A tibble: 6 × 2
#>   feature            importance
#>   <chr>                   <dbl>
#> 1 ratings_value           27.5 
#> 2 ratings_atmosphere      24.3 
#> 3 ratings_speed           16.5 
#> 4 ratings_safety          15.6 
#> 5 ratings_venue           12.5 
#> 6 ratings_commentary       3.58
```
