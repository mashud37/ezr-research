# Percentages for a batch of questions at once

Runs
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
over several columns and stacks the results into one tidy table with a
`variable` column identifying the source question and a shared `answer`
column – handy for tabulating a whole block of questions (e.g. every
`demo_` variable) in a single call.

## Usage

``` r
calc_percentage_batch(
  data = NULL,
  ...,
  by = NULL,
  sort = c("none", "desc", "asc"),
  digits = 0,
  na_rm = TRUE,
  drop = NULL,
  weights = NULL,
  clean_names = FALSE,
  prefix = NULL
)
```

## Arguments

- data:

  A data frame.

- ...:

  Columns to tabulate, using tidyselect (e.g. `starts_with("demo_")` or
  `demo_gender, demo_edu`).

- by, sort, digits, na_rm, drop, weights:

  Passed to
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
  (so a `wpct` column appears when weighting is active, and `drop`
  removes unwanted answers from every question).

- clean_names:

  If `TRUE`, tidy each `variable` with
  [`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md)
  instead of reporting the raw column name.

- prefix:

  Optional question prefix to strip from `variable`, e.g. `"ratings_"`.
  Implies `clean_names`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`variable`, `answer`, `n`, `pct` (plus any `by` columns).

## Details

Each selected column is tabulated with
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
and the results are row-bound, with a `variable` column naming the
source question and the answers collected into a shared character
`answer` column (factor levels differ between questions, so they are
coerced to character when stacked). This is the tidy long shape you want
for faceted plots or a single export of a whole question block. To send
each question to its own Excel tab instead, see
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md).

`variable` is the raw column name by default. Set `clean_names = TRUE`
(or name a `prefix`) to get the same tidied wording
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
and
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
produce, which is what lets a batch table join to a model table on the
question name.

## See also

[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md).

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
calc_percentage_batch(podracing_survey, demo_gender, demo_job)
#> # A tibble: 8 × 4
#>   variable    answer                  n   pct
#>   <chr>       <chr>               <int> <dbl>
#> 1 demo_gender Female                399    42
#> 2 demo_gender Male                  525    55
#> 3 demo_gender Non-binary             27     3
#> 4 demo_job    Employed full-time    447    46
#> 5 demo_job    Employed part-time    129    13
#> 6 demo_job    Not in labour force   113    12
#> 7 demo_job    Student               218    23
#> 8 demo_job    Unemployed             59     6

calc_percentage_batch(podracing_survey, starts_with("demo_"))
#> # A tibble: 85 × 4
#>    variable answer     n   pct
#>    <chr>    <chr>  <int> <dbl>
#>  1 demo_age 16       103    10
#>  2 demo_age 17        13     1
#>  3 demo_age 18        20     2
#>  4 demo_age 19        21     2
#>  5 demo_age 20        20     2
#>  6 demo_age 21        16     2
#>  7 demo_age 22        16     2
#>  8 demo_age 23        24     2
#>  9 demo_age 24        23     2
#> 10 demo_age 25        32     3
#> # ℹ 75 more rows

# tidy question names, with the block's prefix removed
calc_percentage_batch(podracing_survey, starts_with("ratings_"),
                      prefix = "ratings_")
#> # A tibble: 30 × 4
#>    variable   answer        n   pct
#>    <chr>      <chr>     <int> <dbl>
#>  1 atmosphere Bad         138    14
#>  2 atmosphere Good        301    30
#>  3 atmosphere Ok          251    25
#>  4 atmosphere Very bad     53     5
#>  5 atmosphere Very good   257    26
#>  6 commentary Bad         330    33
#>  7 commentary Good        154    15
#>  8 commentary Ok          323    32
#>  9 commentary Very bad    158    16
#> 10 commentary Very good    35     4
#> # ℹ 20 more rows
```
