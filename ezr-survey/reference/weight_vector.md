# Compute the per-respondent survey weights

Returns the weight vector a scheme implies for a dataset – the same
numbers the summary helpers use internally – so you can inspect them,
attach them as a column, or feed them to another tool.

## Usage

``` r
weight_vector(data = NULL, weights = NULL)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- weights:

  A weighting scheme (any form accepted by
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)).
  If `NULL` (default), the session scheme is used.

## Value

A numeric vector of length `nrow(data)`, normalised to mean 1.

## Details

This is the function behind the automatic weighting: each respondent's
weight is `target_share / sample_share` for their category (raked across
variables when there are several), normalised so the weighted base
equals the unweighted one. Pair it with
[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)'s
reported design effect to judge how much precision the weighting costs.

## See also

[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md),
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

Other weighting:
[`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md),
[`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)

## Examples

``` r
target <- c(variable = "demo_gender",
            "Male" = 0.49, "Female" = 0.50, "Non-binary" = 0.01)
w <- weight_vector(podracing_survey, target)

# The sample under-represents women, so their weights are above 1 and the
# weighted share moves towards the target. Categories the target does not
# mention keep a weight of 1, which is why their shares do not move.
podracing_survey %>%
  mutate(weight = w) %>%
  group_by(demo_gender) %>%
  summarise(
    unweighted_pct = round(n() / nrow(podracing_survey) * 100, 1),
    weighted_pct = round(sum(weight) / nrow(podracing_survey) * 100, 1)
  )
#> # A tibble: 5 × 3
#>   demo_gender            unweighted_pct weighted_pct
#>   <chr>                           <dbl>        <dbl>
#> 1 ""                                3.2          3.2
#> 2 "Female"                         39.9         47.5
#> 3 "Male"                           52.5         46.6
#> 4 "Non-binary"                      2.7          1  
#> 5 "Prefer not to answer"            1.7          1.7
```
