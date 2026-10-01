# Cross-tabulate two survey questions

Builds a crosstab from two categorical columns: `x` forms the rows and
`y` the columns. The cell contents are chosen with `cell` – counts or
row/column/total percentages – or, when a numeric `value` column is
supplied, an aggregate of that column (e.g. the mean spend) for each `x`
by `y` combination. Registered orders (see
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md))
are applied to `x` and `y` automatically, and a factor column keeps its
own level order when no order is registered.

## Usage

``` r
crosstab(
  data = NULL,
  x,
  y,
  cell = c("count", "row_pct", "col_pct", "total_pct"),
  value = NULL,
  fn = mean,
  wide = TRUE,
  digits = NULL,
  na_rm = TRUE,
  drop = NULL,
  weights = NULL
)
```

## Arguments

- data:

  A data frame.

- x:

  Row variable (unquoted).

- y:

  Column variable (unquoted).

- cell:

  What to put in each cell when `value` is not given: `"count"`
  (default), `"row_pct"`, `"col_pct"` or `"total_pct"`.

- value:

  Optional numeric column (unquoted) to aggregate per cell instead of
  counting.

- fn:

  Aggregation function used with `value`. Default
  [`mean()`](https://rdrr.io/r/base/mean.html).

- wide:

  If `TRUE` (default), return one row per `x` with a column per `y`
  level; if `FALSE`, return the tidy long form.

- digits:

  Decimal places for percentage / aggregated cells. Default `0` for
  percentages, `2` when `value` is supplied.

- na_rm:

  Drop blanks / non-answers in `x`, `y` (and `NA` in `value`). Default
  `TRUE`.

- drop:

  Optional character vector of answer values to remove from both `x` and
  `y` before tabulating (e.g. `c("Other")`), matched case-insensitively.
  Defaults to the `drop_answers` option. See
  [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md).

- weights:

  Survey weighting: `NULL` (default) uses the session scheme from
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  if set; `FALSE` forces unweighted; or pass an ad-hoc scheme. When
  weighting is active the cells default to weighted values – weighted
  counts, weighted percentages, or (for a numeric `value`) the weighted
  mean.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html): wide (x
plus one column per y level) or long (`x`, `y`, `value`). The long form
refuses an `x` or `y` that is itself called `value`, since the two
columns would share a name.

## Details

Choose what the cells mean with `cell`: `"row_pct"` makes each **row**
sum to 100 (the distribution of `y` within each `x`), `"col_pct"` makes
each **column** sum to 100, `"total_pct"` is the share of the whole
table, and `"count"` is the raw frequency. Supplying a numeric `value`
switches the cells to an aggregate of that column – by default the mean
– which answers questions like "what is the average NPS for each region
by gender?". Blanks and non-answers in `x`/`y` are dropped when
`na_rm = TRUE`. Any registered orders
([`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md))
set the row/column ordering automatically; a factor without one keeps
its own level order; anything else stays in data order.

## See also

[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`compare_values()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/compare_values.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md).

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
# counts
crosstab(podracing_survey, demo_gender, region)
#> # A tibble: 3 × 6
#>   demo_gender  Asia Europe `Latin America` `North America` Oceania
#>   <chr>       <dbl>  <dbl>           <dbl>           <dbl>   <dbl>
#> 1 Female         23    120              33             208      15
#> 2 Male           31    177              42             253      22
#> 3 Non-binary      3      7              NA              14       3

# row percentages: gender split within each region (each row ~ 100)
crosstab(podracing_survey, region, demo_gender, cell = "row_pct")
#> # A tibble: 5 × 4
#>   region        Female  Male `Non-binary`
#>   <chr>          <dbl> <dbl>        <dbl>
#> 1 Asia              40    54            5
#> 2 Europe            39    58            2
#> 3 Latin America     44    56           NA
#> 4 North America     44    53            3
#> 5 Oceania           38    55            8

# mean NPS for each region x gender cell
crosstab(podracing_survey, region, demo_gender, value = nps_value, fn = mean)
#> # A tibble: 5 × 4
#>   region        Female  Male `Non-binary`
#>   <chr>          <dbl> <dbl>        <dbl>
#> 1 Asia            7.7   8            9.33
#> 2 Europe          7.57  7.53         8.29
#> 3 Latin America   7.67  7.71        NA   
#> 4 North America   7.42  7.57         6.79
#> 5 Oceania         7.53  8            7.67
```
