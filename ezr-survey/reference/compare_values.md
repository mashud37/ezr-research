# Compare a metric between two datasets (e.g. two events or waves)

Joins a `current` and a `previous` table on a key column and computes
the difference of a metric – for example feature `performance` from two
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
outputs, or `pct` from two
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
tables for two events. The result feeds straight into
[`plot_diff()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_diff.md).

## Usage

``` r
compare_values(current, previous, by = "feature", value = "performance")
```

## Arguments

- current, previous:

  Data frames sharing a key column and a metric column.

- by:

  Name of the key column to join on. Default `"feature"`.

- value:

  Name of the metric column to compare. Default `"performance"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with the
key column, `previous`, `current` and `difference`
(`current - previous`).

## Details

The join is a left join keyed on `by` with `previous` on the left, so
the row set follows the previous period and `difference` is
`current - previous` (a positive number means it went up). Keys present
only in `current` are dropped; keys missing from `current` get an `NA`
difference. The inputs are deliberately generic two-column-or-more
tables, so the same function compares feature `performance` from two
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
runs, `pct` from two
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
tables for two events, or any other keyed metric.

## See also

[`plot_diff()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_diff.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

Other compare:
[`plot_diff()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_diff.md)

## Examples

``` r
a <- data.frame(feature = c("price", "quality"), performance = c(3.1, 4.2))
b <- data.frame(feature = c("price", "quality"), performance = c(2.8, 4.4))
compare_values(current = b, previous = a)
#> # A tibble: 2 × 4
#>   feature previous current difference
#>   <chr>      <dbl>   <dbl>      <dbl>
#> 1 price        3.1     2.8     -0.300
#> 2 quality      4.2     4.4      0.200
```
