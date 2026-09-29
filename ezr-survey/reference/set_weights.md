# Set a survey weighting scheme for the session

Defines target shares for one or more categorical variables (e.g. a
known population split by gender or region). Once set, the summary
helpers
([`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md))
weight their results automatically, so the weighted margins match your
targets. Pass `weights = FALSE` to any of them to opt out for a single
call.

## Usage

``` r
set_weights(...)
```

## Arguments

- ...:

  One scheme per variable. Two forms are accepted:

  - **vector form** (one argument per variable) carrying a `variable`
    entry and a share per category:
    `c(variable = "demo_gender", Male = 0.49, Female = 0.50, "Non-binary" = 0.01)`;

  - **named form**: `demo_gender = c(Male = 0.49, Female = 0.50)`, where
    the argument name is the column. Shares need not sum to 1 – they are
    normalised per variable (so raw percentages or counts work too).

## Value

Invisibly, the parsed scheme (a named list of normalised targets).

## Details

With a single variable the weights are exact post-stratification:
`target_share / sample_share` for each category. With several variables
the weights are found by raking (iterative proportional fitting) so
every variable's weighted margin matches its targets. Weights are
normalised to mean 1 (so the weighted base equals the sample size), and
respondents whose weighting value is blank / a non-answer (see
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md))
are left unadjusted. A category that appears in the data but is missing
from your targets is an error – give every observed category a share. If
a default dataset is set, this prints the Kish design effect and the
effective sample size so you can see the precision cost.

## See also

[`clear_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
[`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md),
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

Other weighting:
[`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md),
[`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
[`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md)

## Examples

``` r
set_weights(c(variable = "demo_gender",
              "Male" = 0.49, "Female" = 0.50,
              "Non-binary" = 0.01))
#> Weighting scheme stored for: demo_gender. It applies once a dataset is in play.
calc_percentage(podracing_survey, satis_return)   # gains a wpct column
#> # A tibble: 5 × 4
#>   satis_return      n   pct  wpct
#>   <ord>         <int> <dbl> <dbl>
#> 1 Likely          270    27    27
#> 2 Not sure        238    24    24
#> 3 Unlikely        162    16    16
#> 4 Very likely     255    26    25
#> 5 Very unlikely    75     8     8
clear_weights()
```
