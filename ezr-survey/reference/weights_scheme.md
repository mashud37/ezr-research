# Inspect or clear the session weighting scheme

Companions to
[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md):
read the stored scheme, test whether one is set, or remove it.

## Usage

``` r
get_weights()

has_weights()

clear_weights()
```

## Value

`get_weights()` returns the scheme (a named list of target vectors;
error if none is set); `has_weights()` returns a logical;
`clear_weights()` returns `TRUE` invisibly.

## Details

`has_weights()` is the safe check before `get_weights()`, which errors
when no scheme is set. `clear_weights()` turns weighting off again, so
the helpers return purely unweighted results.

## See also

[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md).

Other weighting:
[`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md),
[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md)

## Examples

``` r
has_weights()
#> [1] FALSE
set_weights(c(variable = "region", Europe = 0.5, "North America" = 0.5))
#> Weighting scheme stored for: region. It applies once a dataset is in play.
get_weights()
#> $region
#>        Europe North America 
#>           0.5           0.5 
#> 
clear_weights()
```
