# Quick-save any ezrsurvey output (plot or table)

Convenience dispatcher: routes ggplots to
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
and data frames / lists to
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
choosing by the object type. Handy at the end of a pipe when you do not
want to think about which saver to call.

## Usage

``` r
save_output(x, path = NULL, ...)
```

## Arguments

- x:

  A ggplot, a data frame, or a (named) list of data frames.

- path:

  Output path; the extension picks the format. `NULL` (default) writes
  `plot.png` or `data.csv`. A bare file name lands in
  `ezrsurvey-outputs/` (created on demand); a path naming a directory
  (`"./x.png"`, `"charts/x.png"`, anything absolute) is used exactly as
  given. See the `output_dir` option.

- ...:

  Passed to
  [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
  or
  [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md).

## Value

`x`, invisibly.

## See also

[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md).

Other save:
[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
[`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
[`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)

## Examples

``` r
tmp_csv <- tempfile(fileext = ".csv")
calc_percentage(podracing_survey, demo_gender) %>% save_output(tmp_csv)

# \donttest{
tmp_png <- tempfile(fileext = ".png")
plot_bars(calc_percentage(podracing_survey, demo_gender)) %>% save_output(tmp_png)
# }
```
