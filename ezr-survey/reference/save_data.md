# Quick-save a table to CSV, TSV or XLSX

A pipe-friendly one-liner for dropping a summary table to disk. The
format is taken from the file extension. For `.xlsx`, pass a single data
frame for one sheet, or a *named* list of data frames to write one sheet
per element. Returns its input invisibly so it can sit mid-pipeline.

## Usage

``` r
save_data(data, path = NULL, na = "", ...)
```

## Arguments

- data:

  A data frame / tibble, or (for `.xlsx`) a named list of them.

- path:

  Output path; the extension sets the format (`.csv`, `.tsv`, `.xlsx`).
  `NULL` (default) writes `data.csv`. A bare file name lands in
  `ezrsurvey-outputs/` (created on demand); a path naming a directory
  (`"./x.csv"`, `"charts/x.csv"`, anything absolute) is used exactly as
  given. See the `output_dir` option.

- na:

  String to write for missing values. Default `""`.

- ...:

  Passed to the underlying writer
  ([`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
  /
  [`readr::write_tsv()`](https://readr.tidyverse.org/reference/write_delim.html)
  /
  [`writexl::write_xlsx()`](https://docs.ropensci.org/writexl//reference/write_xlsx.html)).

## Value

`data`, invisibly.

## Details

The format follows the file extension: `.csv`/`.tsv` via readr, `.xlsx`
via the suggested `writexl` package. For an Excel workbook, pass one
data frame for a single sheet, or a *named* list of data frames for one
sheet each. Returns its input invisibly so it can sit mid-pipeline. To
send several separate calls to their own tabs in one line, see
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md).

## See also

[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md).

Other save:
[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
[`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)

## Examples

``` r
tab <- calc_percentage(podracing_survey, demo_gender)
tmp <- tempfile(fileext = ".csv")
save_data(tab, tmp)
file.exists(tmp)
#> [1] TRUE
```
