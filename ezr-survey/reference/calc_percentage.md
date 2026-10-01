# Count a categorical question as percentages

The headline helper: replaces the ubiquitous
`count(x) %>% mutate(pct = round(n / sum(n) * 100)) %>% select(-n)`
dance with a single call. Returns both the raw counts and the
percentages, optionally grouped by one or more variables and optionally
pivoted to a wide cross-tabulation.

## Usage

``` r
calc_percentage(
  data = NULL,
  column,
  by = NULL,
  sort = c("none", "desc", "asc"),
  levels = NULL,
  digits = 0,
  wide = FALSE,
  na_rm = TRUE,
  drop = NULL,
  weights = NULL
)
```

## Arguments

- data:

  A data frame. If omitted, the session default set with
  [`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md)
  is used.

- column:

  The categorical column to tabulate (unquoted).

- by:

  Optional grouping column(s). Percentages are computed *within* each
  group so they sum to ~100 per group. Pass one bare name (`by = year`)
  or several with [`c()`](https://rdrr.io/r/base/c.html)
  (`by = c(year, game)`).

- sort:

  Level ordering of `column`: `"none"` (default, data order), `"desc"`
  (largest percentage first) or `"asc"`.

- levels:

  Optional character vector giving an explicit level order for `column`
  (the "custom" ordering mode). Overrides `sort`. If omitted and
  `sort = "none"`, a registered order for this variable is applied
  automatically (see
  [`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)),
  and failing that a factor keeps its own level order.

- digits:

  Decimal places for the percentage. Defaults to `0`.

- wide:

  If `TRUE`, pivot to one row per `by` group and one column per answer
  (dropping `n`), the shape a wide summary table needs. Defaults to
  `FALSE` (tidy long form).

- na_rm:

  If `TRUE` (default), blanks and "Prefer not to answer" responses (see
  [`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md))
  are dropped before counting.

- drop:

  Optional character vector of answer values to remove before counting
  (e.g. `c("Other", "Don't know")`), so the kept answers re-base to
  ~100%. Matching is case-insensitive (see
  [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md)).
  Defaults to the `drop_answers` option (`NULL` = drop nothing; see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).

- weights:

  Survey weighting for this call: `NULL` (default) uses the session
  scheme from
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  if one is set; `FALSE` forces unweighted; or pass an ad-hoc scheme
  (any form
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  accepts) to weight just this call. When weighting is active a `wpct`
  column (weighted percentage) is added beside `n` and `pct`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`column`, `n` and `pct` (and `wpct` when weighting is active) in long
form, or one row per group with an answer column each (wide form).

## Details

Percentages are computed *within* each group, so they sum to about 100
per group (subject to rounding). The level order of `column` is decided
in this order of precedence: an explicit `levels` argument; then a
non-`"none"` `sort`; then a registered order for the variable (see
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md));
then the column's own levels, when it is a factor; otherwise data order.
When `by` is omitted, the `default_by` option is used if set (see
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)),
so you can apply a standard breakdown without repeating it.
`wide = TRUE` pivots to one row per group with a column per answer – the
shape you want for a slide table or an Excel tab.

## See also

[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
for check-all-that-apply questions,
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md)
for many questions at once,
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)
for numeric variables,
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)
for reusable level orders.

Other summaries:
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
calc_percentage(podracing_survey, demo_gender)
#> # A tibble: 3 × 3
#>   demo_gender     n   pct
#>   <chr>       <int> <dbl>
#> 1 Female        399    42
#> 2 Male          525    55
#> 3 Non-binary     27     3

# largest first
calc_percentage(podracing_survey, demo_gender, sort = "desc")
#> # A tibble: 3 × 3
#>   demo_gender     n   pct
#>   <fct>       <int> <dbl>
#> 1 Male          525    55
#> 2 Female        399    42
#> 3 Non-binary     27     3

# grouped and pivoted to a wide cross-tab
calc_percentage(podracing_survey, satis_return, by = region, wide = TRUE)
#> # A tibble: 5 × 6
#>   region        Likely `Not sure` Unlikely `Very likely` `Very unlikely`
#>   <chr>          <dbl>      <dbl>    <dbl>         <dbl>           <dbl>
#> 1 Asia              24         25       12            34               5
#> 2 Europe            28         25       16            25               6
#> 3 Latin America     30         21       11            28              10
#> 4 North America     26         24       17            24               8
#> 5 Oceania           31         12       24            24              10
```
