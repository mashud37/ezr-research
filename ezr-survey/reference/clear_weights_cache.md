# Forget cached survey weights

Empties the session's cache of computed weight vectors. Weighting the
same rows under the same scheme always gives the same numbers, so
ezrsurvey works them out once and reuses them; a table crossing every
question against every group would otherwise re-run the raking for each
cell.

## Usage

``` r
clear_weights_cache()
```

## Value

`TRUE`, invisibly.

## Details

The cache keys on the weighting columns' own contents, so editing the
data produces different weights without any action from you. Clearing it
by hand is only needed to reclaim memory, or after changing a weighting
variable in place inside an object the cache has already seen.
[`clear_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
clears it too.

## See also

[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md).

Other weighting:
[`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md)

## Examples

``` r
clear_weights_cache()
```
