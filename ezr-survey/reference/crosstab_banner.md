# Build a master banner (cross-tab) table

Produces the market-research "banner" table: one master table with a
stack of question variables down the side (`rows`) and one or more
grouping variables across the top (`cols`), plus an **Overall** column
for the whole sample. Categorical questions become column-percentage
blocks (each banner column sums to ~100 within the block); numeric
questions become a mean / median / sd / quartile block. It generalises
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
from a single pair to a whole table, and picks the cell content per
question automatically.

## Usage

``` r
crosstab_banner(
  data = NULL,
  rows,
  cols,
  cell = c("auto", "pct", "count", "mean", "diff"),
  stats = c("mean", "median", "sd", "p25", "p75"),
  total = TRUE,
  digits = NULL,
  na_rm = TRUE,
  drop = NULL,
  weights = NULL,
  max_levels = 20,
  long = FALSE,
  flextable = FALSE,
  checkpoint = NULL,
  confirm = NULL
)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- rows:

  Stub variables, down the side (tidyselect, e.g.
  `c(satis_return, demo_edu)` or `starts_with("ratings_")`). If omitted,
  every eligible variable is used (see `max_levels` and Details).

- cols:

  Banner / grouping variables, across the top (tidyselect). Pass several
  to get several spanning column groups. If omitted, every eligible
  variable is used, giving a full variable-by-variable banner.

- cell:

  What each body cell holds: `"auto"` (default) uses column percentages
  for categorical questions and a statistics block for numeric ones;
  `"pct"` forces column percentages; `"count"` uses (weighted) counts;
  `"mean"` forces a numeric mean (errors on a categorical question);
  `"diff"` shows each cell's difference from the Overall column
  (percentage points, or mean difference for numeric questions).

- stats:

  For numeric questions, which statistics form the block. Any of
  `"mean"`, `"median"`, `"sd"`, `"p25"`, `"p75"`. Default all five.

- total:

  Include the whole-sample **Overall** column. Default `TRUE`.

- digits:

  Decimal places. `NULL` (default) uses `0` for percentages / counts and
  `2` for numeric statistics; a value overrides both.

- na_rm:

  Drop blanks / non-answers in the questions and banner variables.
  Default `TRUE`.

- drop:

  Answer values to remove before tabulating (see
  [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md)),
  passed to the underlying
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
  calls. Defaults to the `drop_answers` option.

- weights:

  Survey weighting: `NULL` (default) uses the session scheme from
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  if set; `FALSE` forces unweighted; or pass an ad-hoc scheme. When
  weighting is active the cells are weighted (weighted percentages,
  counts, means and quartiles).

- max_levels:

  When `rows` / `cols` are omitted, the largest number of distinct
  answers a categorical variable may have to be used automatically
  (default `20`). Bigger categorical variables, identifier columns and
  free-text are skipped; numeric scales are always kept as stub rows.

- long:

  If `TRUE`, return the tidy long form (`variable`, `item`, `group`,
  `group_item`, `value`) instead of the wide master table. Default
  `FALSE`.

- flextable:

  If `TRUE`, return a
  [flextable](https://davidgohel.github.io/flextable/reference/flextable.html)
  with the two-row banner header ready for a slide or Word report.
  Default `FALSE`. Requires the suggested `flextable` package.

- checkpoint:

  Save each question as it finishes, so re-running the same call picks
  up where an interrupted run stopped. `TRUE` keeps the file under
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) and
  deletes it once the run completes; a file path puts it where you
  choose and leaves it there for you to manage. `NULL` (default) or
  `FALSE` writes nothing. See Details and
  [`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md).

- confirm:

  When `rows` / `cols` are left to the automatic selection, show which
  variables were chosen and which were skipped, and wait for a yes
  before the run starts. `NULL` (default) follows the `confirm` option,
  which asks in an interactive session and never asks in a script;
  `TRUE` or `FALSE` force it either way. Answering no returns `NULL` and
  computes nothing.

## Value

By default a wide
[tibble](https://tibble.tidyverse.org/reference/tibble.html):
`variable`, `item`, `Overall`, then one column per banner item. The
banner grouping (which column belongs to which top-row variable) is
stored in the `"banner_spanners"` attribute, which `flextable = TRUE`
turns into a spanning two-row header. With `long = TRUE`, the tidy long
form.

## Details

A tibble has a single header row, so the two-row banner header (each
grouping variable's name spanning its items) cannot be stored in the
data itself: the wide return carries the grouping in the
`"banner_spanners"` attribute and `flextable = TRUE` renders the real
spanning header. Column percentages are computed *within* each banner
column, so every column (Overall included) sums to about 100 down each
question block. Registered orders
([`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md))
set the item and banner-column ordering automatically. Passing the same
selection to `rows` and `cols` gives the full
every-question-by-every-question matrix (a variable is never crossed
with itself). Supplying only the data frame does this automatically:
every variable with at most `max_levels` distinct answers becomes both a
stub and a banner group, numeric scales are added as stub statistics
blocks, and identifier / free-text columns are skipped (and named in a
message). That selection decides the whole table, so an interactive
session prints it and waits for a yes before starting the run (see
`confirm`). Check-all-that-apply blocks (columns sharing a prefix that
each hold one option or blank, such as `motivations_*`) are recognised
as a single multi-select stub question and tabulated with
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
whose base is the respondents who picked any option (so those rows can
sum past 100). Multi-select blocks appear as stubs only, not banner
groups, and are unweighted.

A full every-variable banner is one
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
per question per grouping variable, so a wide survey takes minutes
rather than seconds. In an interactive session it reports which question
it is on, with an estimate of the time left;
`ezrsurvey_options(progress = FALSE)` turns that off, and scripts are
silent by default. `checkpoint = TRUE` additionally saves each question
as it completes, so re-running the identical call after an interruption
resumes instead of starting again. The managed file is named after the
run's own fingerprint, so a call finds its own interrupted run and a
call with different data or arguments never sees it, and it is deleted
as soon as the table is built. Pass a path instead if you would rather
choose the location; that file is yours, so the package neither deletes
it nor counts it as one of its own.
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md)
empties the managed folder if a run was interrupted and never repeated.

## See also

[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
for a single pair,
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md)
for stacked one-variable percentages,
[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md).

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)

## Examples

``` r
# gender and region banner over two questions (column percentages)
crosstab_banner(podracing_survey,
                rows = c(satis_return, demo_edu),
                cols = c(demo_gender, region))
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

# numeric questions become a mean / median / sd / quartile block
crosstab_banner(podracing_survey,
                rows = c(nps_value, demo_age),
                cols = demo_gender)
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

# each cell as its difference from the Overall column
crosstab_banner(podracing_survey, rows = satis_return,
                cols = region, cell = "diff")
#> # A tibble: 5 × 8
#>   variable    item  Overall  Asia Europe `Latin America` `North America` Oceania
#>   <chr>       <chr>   <dbl> <dbl>  <dbl>           <dbl>           <dbl>   <dbl>
#> 1 satis_retu… Like…      27    -3      1               3              -1       4
#> 2 satis_retu… Not …      24     1      1              -3               0     -12
#> 3 satis_retu… Unli…      16    -4      0              -5               1       8
#> 4 satis_retu… Very…      26     8     -1               2              -2      -2
#> 5 satis_retu… Very…       8    -3     -2               2               0       2

# \donttest{
# full variable-by-variable banner: just pass the data frame
crosstab_banner(podracing_survey)
#> crosstab_banner: skipped 3 identifier / free-text / high-cardinality column(s): respondent_id, nps_com, show_com. Raise max_levels or name them in rows/cols to include them.
#> # A tibble: 129 × 126
#>    variable   item  Overall email in_app panel socials Female  Male `Non-binary`
#>    <chr>      <chr>   <dbl> <dbl>  <dbl> <dbl>   <dbl>  <dbl> <dbl>        <dbl>
#>  1 collector  email    28    NA     NA    NA      NA     29    29           33  
#>  2 collector  in_a…    16    NA     NA    NA      NA     15    17           26  
#>  3 collector  panel    35    NA     NA    NA      NA     35    34           33  
#>  4 collector  soci…    20    NA     NA    NA      NA     21    20            7  
#>  5 demo_age   mean     32.6  32.3   32.5  32.5    33.2   32.9  32.3         31.2
#>  6 demo_age   medi…    32    32     33    32      32     33    32           31  
#>  7 demo_age   sd       11.2  11.5   10.5  11.4    11.0   11.4  11.1         11.1
#>  8 demo_age   p25      24    24     25    23.5    25     25    24           23.5
#>  9 demo_age   p75      40    40     39    40      41     40    40           37  
#> 10 demo_gend… Fema…    42    42     39    43      44     NA    NA           NA  
#> # ℹ 119 more rows
#> # ℹ 116 more variables: `Bachelor or equivalent` <dbl>,
#> #   `Doctoral or equivalent` <dbl>, `Lower secondary` <dbl>,
#> #   `Master or equivalent` <dbl>, `Primary or less` <dbl>,
#> #   `Short-cycle tertiary` <dbl>, `Upper secondary` <dbl>, Australia <dbl>,
#> #   Brazil <dbl>, Canada <dbl>, France <dbl>, Germany <dbl>, Japan <dbl>,
#> #   Mexico <dbl>, Sweden <dbl>, `United Kingdom` <dbl>, …
# }
```
