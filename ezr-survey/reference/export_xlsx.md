# Export several tables to one Excel workbook, a tab each

A quick way to drop a handful of summaries into a single `.xlsx`, one
per worksheet – e.g.
`export_xlsx(calc_percentage(d, a), calc_percentage(d, b), path = "out.xlsx")`.
Tabs are named from the argument names you give, else from each table's
question/first column, else `Sheet1`, `Sheet2`, ...

## Usage

``` r
export_xlsx(..., path = NULL, sheet_names = NULL)
```

## Arguments

- ...:

  Data frames to write, one per tab. Name them to set tab names (e.g.
  `gender = calc_percentage(d, demo_gender)`).

- path:

  Output `.xlsx` path. `NULL` (default) writes `tables.xlsx`. A bare
  file name lands in `ezrsurvey-outputs/` (created on demand); a path
  naming a directory (`"./x.xlsx"`, `"charts/x.xlsx"`, anything
  absolute) is used exactly as given. See the `output_dir` option.

- sheet_names:

  Optional character vector of tab names (overrides argument names).

## Value

Invisibly `path`.

## Details

Each argument becomes one worksheet. Tab names are taken from the
argument names you give (`gender = ...`), otherwise from each table's
`variable` column or first column, otherwise `Sheet1`, `Sheet2`, ...;
they are then cleaned to valid, unique Excel names (\<= 31 characters,
with `[ ] : * ? / \\` stripped). This is the quick way to drop a set of
summaries into one workbook for a colleague. Requires the suggested
`writexl` package.

\[ \]: R:%20

## See also

[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md)
for a single table or a pre-named list.

Other save:
[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)

## Examples

``` r
tmp <- tempfile(fileext = ".xlsx")
export_xlsx(
  gender = calc_percentage(podracing_survey, demo_gender),
  calc_percentage(podracing_survey, demo_job),
  path = tmp
)
file.exists(tmp)
#> [1] TRUE
```
