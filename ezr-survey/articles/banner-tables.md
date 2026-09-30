# Banner tables

``` r

library(ezrsurvey)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> Loading required package: ggplot2
#> Loading required package: tidyr
#> Loading required package: tibble
#> Loading required package: readr
#> Loading required package: stringr
#> Loading required package: purrr
```

The banner is the table a client actually works from: every question
down the side, every way of splitting the sample across the top, and one
column for the sample as a whole. It is the first deliverable of most
projects and the one that takes longest to build by hand, because it is
the same cross-tab written out dozens of times.

[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)
writes it in one call.

## The shape of it

Name the questions as `rows` and the splits as `cols`.

``` r

crosstab_banner(
  podracing_survey,
  rows = c(satis_return, demo_edu),
  cols = c(demo_gender, region)
)
#> # A tibble: 12 × 11
#>    variable item  Overall Female  Male `Non-binary`  Asia Europe `Latin America`
#>    <chr>    <chr>   <dbl>  <dbl> <dbl>        <dbl> <dbl>  <dbl>           <dbl>
#>  1 demo_edu Bach…      25     26    25           22    23     28              15
#>  2 demo_edu Doct…       4      3     4            4     4      3               5
#>  3 demo_edu Lowe…      11     12    11           15    12     10              10
#>  4 demo_edu Mast…      13     12    13           19    11     15               9
#>  5 demo_edu Prim…       4      3     5            7     7      6               4
#>  6 demo_edu Shor…      13     14    12            4    19     11              17
#>  7 demo_edu Uppe…      30     30    31           30    25     26              41
#>  8 satis_r… Like…      27     28    27           15    24     28              30
#>  9 satis_r… Not …      24     25    22           33    25     25              21
#> 10 satis_r… Unli…      16     14    17           26    12     16              11
#> 11 satis_r… Very…      26     24    26           26    34     25              28
#> 12 satis_r… Very…       8      9     7            0     5      6              10
#> # ℹ 2 more variables: `North America` <dbl>, Oceania <dbl>
```

Three things are worth noticing in that output. Every question keeps its
own answers as rows, so questions with different scales stack in one
table. The `Overall` column is the whole sample, which is what a reader
compares each group against. And the percentages are column percentages:
they run down each group, so they answer “what does this group look
like”, not “where do this answer’s respondents come from”.

`tidyselect` helpers work, which is how a block of rating questions goes
in:

``` r

crosstab_banner(
  podracing_survey,
  rows = dplyr::starts_with("ratings_"),
  cols = demo_gender
)
#> # A tibble: 30 × 6
#>    variable           item      Overall Female  Male `Non-binary`
#>    <chr>              <chr>       <dbl>  <dbl> <dbl>        <dbl>
#>  1 ratings_atmosphere Bad            14     13    15            7
#>  2 ratings_atmosphere Good           30     29    32           15
#>  3 ratings_atmosphere Ok             25     28    21           48
#>  4 ratings_atmosphere Very bad        5      5     6            0
#>  5 ratings_atmosphere Very good      26     25    26           30
#>  6 ratings_commentary Bad            33     33    33           33
#>  7 ratings_commentary Good           15     15    16           11
#>  8 ratings_commentary Ok             32     33    32           37
#>  9 ratings_commentary Very bad       16     15    17           15
#> 10 ratings_commentary Very good       4      4     3            4
#> # ℹ 20 more rows
```

## Numbers and categories in one table

A numeric question has no answers to count, so counting it would produce
a row per distinct value. Handed one, the banner switches to a
statistics block instead, and says so by labelling the rows:

``` r

crosstab_banner(
  podracing_survey,
  rows = c(nps_value, demo_age),
  cols = demo_gender
)
#> # A tibble: 10 × 6
#>    variable  item   Overall Female  Male `Non-binary`
#>    <chr>     <chr>    <dbl>  <dbl> <dbl>        <dbl>
#>  1 demo_age  mean     32.6   32.9  32.3         31.2 
#>  2 demo_age  median   32     33    32           31   
#>  3 demo_age  sd       11.2   11.4  11.1         11.1 
#>  4 demo_age  p25      24     25    24           23.5 
#>  5 demo_age  p75      40     40    40           37   
#>  6 nps_value mean      7.56   7.51  7.61         7.56
#>  7 nps_value median    8      8     8            8   
#>  8 nps_value sd        1.76   1.81  1.72         1.69
#>  9 nps_value p25       6      6     7            7   
#> 10 nps_value p75       9      9     9            8
```

`cell` overrides the choice when you want something specific: `"pct"`,
`"count"`, `"mean"`, or `"diff"` for each group’s distance from
`Overall`, which is the version to read when you are hunting for what
makes a group different.

``` r

crosstab_banner(
  podracing_survey,
  rows = satis_return,
  cols = demo_gender,
  cell = "diff"
)
#> # A tibble: 5 × 6
#>   variable     item          Overall Female  Male `Non-binary`
#>   <chr>        <chr>           <dbl>  <dbl> <dbl>        <dbl>
#> 1 satis_return Likely             27      1     0          -12
#> 2 satis_return Not sure           24      1    -2            9
#> 3 satis_return Unlikely           16     -2     1           10
#> 4 satis_return Very likely        26     -2     0            0
#> 5 satis_return Very unlikely       8      1    -1           -8
```

## Weighting

A banner built on a weighted sample has to be weighted in every cell,
not corrected afterwards. Set the scheme once and it applies throughout:

``` r

set_weights(c(variable = "demo_gender",
              "Male" = 0.49, "Female" = 0.50, "Non-binary" = 0.01))
#> Weighting scheme stored for: demo_gender. It applies once a dataset is in play.

crosstab_banner(
  podracing_survey,
  rows = satis_return,
  cols = region
)
#> # A tibble: 5 × 8
#>   variable    item  Overall  Asia Europe `Latin America` `North America` Oceania
#>   <chr>       <chr>   <dbl> <dbl>  <dbl>           <dbl>           <dbl>   <dbl>
#> 1 satis_retu… Like…      27    23     28              29              27      31
#> 2 satis_retu… Not …      24    26     25              23              24      13
#> 3 satis_retu… Unli…      16    12     15              11              17      25
#> 4 satis_retu… Very…      25    33     25              28              24      21
#> 5 satis_retu… Very…       8     6      7               9               8      10

clear_weights()
```

Weights are computed once per dataset and scheme and then reused, rather
than re-running the raking loop for every cell.
[`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md)
empties that store if you need to force a recalculation.

## Letting it choose the variables

Called with no `rows` or `cols`, the banner picks them itself: every
question that looks like a question, crossed by every variable that
looks like a split. That choice decides the entire table, so in an
interactive session it shows the choice and waits:

    Banner variables chosen automatically: 34 question(s) across 12 grouping variable(s).
      Questions (34): satis_return, demo_gender, ...
      Grouping variables (12): demo_gender, region, ...
      Skipped (11): respondent_id, start_date, nps_com, ...
      Name `rows` / `cols` yourself, or raise `max_levels` (now 20), to change this.
    Continue? [Y/n]

Identifier columns, free text and anything with more distinct answers
than `max_levels` are left out. Naming the variables yourself is your
own decision and is never questioned. The prompt only appears when
someone is there to answer it, so an unattended script cannot stall on
it; `ezrsurvey_options(confirm = FALSE)` removes it and `TRUE` forces
it.

## Runs long enough to worry about

A full every-variable banner on a wide survey is minutes of work. While
it runs it says where it is, with an estimate built from the throughput
measured so far rather than a guess:

    Banner table: 34 question(s) across 12 grouping variable(s)
    [7/34] satis_return  (about 2m left)

Progress reporting is on in an interactive session and silent in
scripts, vignettes and `R CMD check`.
`ezrsurvey_options(progress = FALSE)` turns it off everywhere.

For a table long enough that losing it would hurt, ask for a checkpoint:

``` r

crosstab_banner(survey, checkpoint = TRUE)           # managed for you
crosstab_banner(survey, checkpoint = "banner.rds")   # or choose the location
```

Each question is saved as it finishes, so re-running the identical call
after a crash carries on from where it stopped. The managed file is
named after the run’s own fingerprint, so a call finds its own
interrupted run and never sees one belonging to different data or
different arguments: a stale file cannot quietly corrupt a table. A
finished run deletes its own checkpoint, and
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md)
clears anything left behind by a run that was never repeated.

## Getting it out

A banner is usually delivered as a spreadsheet, and `long = TRUE` gives
the tidy form to pivot or join instead of the printed one.

``` r

banner <- crosstab_banner(survey, rows = ..., cols = ...)

export_xlsx("Banner" = banner, path = "banner.xlsx")
save_data(banner, "banner.csv")
```

`flextable = TRUE` returns a formatted table ready to drop on a slide or
into a Word document through
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md).
