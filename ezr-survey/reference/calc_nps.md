# Net Promoter Score

Computes NPS from a 0-10 recommendation question. The score is
`% promoters - % detractors`, equivalently `100 * mean(nps_group(x))`
over the signed `-1/0/1` coding (see
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md)).

## Usage

``` r
calc_nps(data = NULL, value, by = NULL, weights = NULL)
```

## Arguments

- data:

  A data frame.

- value:

  The 0-10 recommendation column (unquoted).

- by:

  Optional grouping column(s); see
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

- weights:

  Survey weighting: `NULL` (default) uses the session scheme from
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  if set; `FALSE` forces unweighted; or pass an ad-hoc scheme. When
  weighting is active `nps` is the weighted score (`n` stays the
  unweighted base).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with `n`
(valid responses), `nps` (an integer from -100 to 100), the three group
shares (`pct_detractors`, `pct_passives`, `pct_promoters`) and the
counts behind them (`detractors`, `passives`, `promoters`), one row per
group when `by` is given. The shares come first because they are what a
report quotes.

## Details

Respondents are bucketed by
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md)
into detractors (0–6), passives (7–8) and promoters (9–10); the score is
the percentage of promoters minus the percentage of detractors, which
equals `100 * mean()` of the signed `-1/0/1` coding. Missing or
out-of-range scores are dropped before the mean. Text answers are
coerced with
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md).
Use
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md)
for the full 0–10 distribution chart and
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md)
for a single-number gauge.

The three group counts and shares are reported alongside the score
because a single NPS hides how it was reached: +20 from 40% promoters
and 20% detractors is a different picture from +20 with 25% and 5%.
Counts are always unweighted respondent counts; the shares follow `nps`,
so they are weighted when a weighting scheme is active. All three shares
and `nps` are rounded to whole numbers independently, so
`pct_promoters - pct_detractors` can land one point away from `nps`; the
identity holds exactly before rounding.

## See also

[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md).

Other modelling:
[`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)

## Examples

``` r
calc_nps(podracing_survey, nps_value)
#> # A tibble: 1 × 8
#>       n   nps pct_detractors pct_passives pct_promoters detractors passives
#>   <int> <dbl>          <dbl>        <dbl>         <dbl>      <int>    <int>
#> 1  1000     7             25           43            32        252      426
#> # ℹ 1 more variable: promoters <int>

calc_nps(podracing_survey, nps_value, by = region)
#> # A tibble: 5 × 9
#>   region            n   nps pct_detractors pct_passives pct_promoters detractors
#>   <chr>         <int> <dbl>          <dbl>        <dbl>         <dbl>      <int>
#> 1 Asia             59    25             19           37            44         11
#> 2 Europe          314     7             23           46            30         73
#> 3 Latin America    82    12             21           46            33         17
#> 4 North America   503     4             28           40            32        141
#> 5 Oceania          42    10             24           43            33         10
#> # ℹ 2 more variables: passives <int>, promoters <int>
```
