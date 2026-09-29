# Export a per-question summary workbook (table + chart per sheet)

Writes one Excel workbook with a worksheet per question, each holding
that question's summary table and its chart. Numeric questions get a
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)
table and a histogram; categorical questions get a
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
table and a
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
chart; check-all-that-apply blocks get a
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
table (based on the respondents who picked any option) and a bar chart.
This is the "hand the client a tabbed workbook" counterpart to the
slide/Word builders
([`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)).
Requires the suggested `openxlsx2` package (the only xlsx writer here
that can embed images).

## Usage

``` r
export_summary_xlsx(
  data = NULL,
  ...,
  path = NULL,
  by = NULL,
  chart = TRUE,
  sort = c("none", "desc", "asc"),
  digits = 0,
  weights = NULL,
  width = 6,
  height = 3.4,
  confirm = NULL
)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- ...:

  Variables to summarise, using tidyselect (e.g.
  `starts_with("ratings_")` or `demo_gender, satis_return`). One
  worksheet per question. If omitted, every question is written: each
  eligible column plus any multi-select block, skipping identifier and
  free-text columns.

- path:

  Output `.xlsx` path. `NULL` (default) writes `summary.xlsx`. A bare
  file name lands in `ezrsurvey-outputs/` (created on demand); a path
  naming a directory (`"./x.xlsx"`, `"charts/x.xlsx"`, anything
  absolute) is used exactly as given. See the `output_dir` option.

- by:

  Optional grouping column(s) for the tables (passed to
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
  /
  [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)
  /
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)).
  The chart is always the ungrouped distribution.

- chart:

  Include the chart beneath each table. Default `TRUE`.

- sort:

  Level ordering for categorical tables, passed to
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md):
  `"none"` (default, respecting any registered order), `"desc"` or
  `"asc"`. The chart always auto-lays-out its bars.

- digits:

  Decimal places for percentages. Default `0`.

- weights:

  Survey weighting, passed to the table and chart helpers (see
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)).
  `NULL` (default) uses the session scheme if set. Multi-select blocks
  are always unweighted.

- width, height:

  Chart size in inches. Default `6 x 3.4`.

- confirm:

  When no variables are named, show which questions were chosen and
  which were skipped, and wait for a yes before writing. `NULL`
  (default) follows the `confirm` option, which asks in an interactive
  session and never asks in a script; `TRUE` or `FALSE` force it either
  way. Answering no writes nothing and returns `NULL`.

## Value

Invisibly the `path` written.

## Details

Worksheets are named from each question (cleaned to valid, unique Excel
names). The table is written from cell `A1`; the chart, when included,
is rendered to a temporary PNG and embedded a few rows below it. A
numeric column (after
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md))
is treated as a scale question (summary + histogram); columns that share
a prefix and each hold a single option or blank (e.g. `motivations_*`)
are treated as one check-all-that-apply question; anything else is
categorical (percentages + bar chart). With no `...`, every question in
the data is written and identifier / free-text columns are skipped (and
named in a message). For a single table or a pre-named list of tables in
one workbook without charts, see
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md)
/
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md).

## See also

[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md).

Other save:
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)

## Examples

``` r
# \donttest{
# named questions
tmp <- tempfile(fileext = ".xlsx")
export_summary_xlsx(podracing_survey, demo_gender, satis_return, nps_value,
                    path = tmp)

# or every question at once (identifier / free-text columns are skipped)
tmp2 <- tempfile(fileext = ".xlsx")
export_summary_xlsx(podracing_survey, path = tmp2)
#> export_summary_xlsx: skipped 3 identifier / free-text column(s): respondent_id, nps_com, show_com.
# }
```
