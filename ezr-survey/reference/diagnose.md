# Survey precision diagnostics for one or more columns

The headline diagnostics wrapper: for each selected column it
auto-detects whether it is a point estimate (numeric, e.g. a 1-5 rating)
or a proportion (categorical), and returns a tidy table of sample size,
estimate, standard error, relative standard error and margin of error –
i.e. the whole appendix "Data info" block as one call.

## Usage

``` r
diagnose(
  data = NULL,
  ...,
  type = c("auto", "mean", "prop"),
  by = NULL,
  z = 1.96,
  digits = 2
)
```

## Arguments

- data:

  A data frame.

- ...:

  Columns to diagnose, using tidyselect (e.g. `starts_with("ratings_")`,
  `demo_gender`).

- type:

  Force the estimate type: `"auto"` (default, detect per column),
  `"mean"` or `"prop"`.

- by:

  Optional grouping column(s); diagnostics are computed within group.

- z:

  Margin-of-error multiplier passed to
  [`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md).
  Defaults to `1.96` (95%).

- digits:

  Decimal places for the numeric output columns. Defaults to `2`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per column (per group), with columns `variable`, `type`, `unit`,
`n`, `estimate`, `se`, `rse`, `moe` and `precision`. For
`type == "mean"`, `unit` is `"points"`; for proportions it is `"ppt"`
(percentage points) and `estimate` is a percentage.

## Details

For categorical columns the reported estimate is the **largest answer
category's** share, which gives a concrete `+/-` percentage-point margin
to quote in a report footnote.

Each column is classified (or forced via `type`) as a point estimate or
a proportion. For numeric columns the estimate is the mean and the error
is in rating points; for categorical columns the estimate is the
**largest answer category's** share, which gives a single concrete `+/-`
percentage-point margin to quote (the largest category is also the worst
case among the observed categories, so it is a sensible headline). The
`precision` column is the five-band rating from
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md).
This is the per-variable form of the report-appendix "Data info" block;
for the narrative bullet-point version see
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md).

## See also

[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md).

Other diagnostics:
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
diagnose(podracing_survey, demo_gender, nps_value)
#> # A tibble: 2 × 9
#>   variable    type  unit       n estimate    se   rse   moe precision     
#>   <chr>       <chr> <chr>  <int>    <dbl> <dbl> <dbl> <dbl> <chr>         
#> 1 demo_gender prop  ppt      951    55.2   1.61  2.92  3.16 high precision
#> 2 nps_value   mean  points  1000     7.56  0.06  0.74  0.11 high precision

diagnose(podracing_survey, starts_with("ratings_"))
#> # A tibble: 6 × 9
#>   variable           type  unit      n estimate    se   rse   moe precision     
#>   <chr>              <chr> <chr> <int>    <dbl> <dbl> <dbl> <dbl> <chr>         
#> 1 ratings_atmosphere prop  ppt    1000     30.1  1.45  4.82  2.84 high precision
#> 2 ratings_commentary prop  ppt    1000     33    1.49  4.51  2.91 high precision
#> 3 ratings_safety     prop  ppt    1000     34.9  1.51  4.32  2.95 high precision
#> 4 ratings_speed      prop  ppt    1000     29.6  1.44  4.88  2.83 high precision
#> 5 ratings_value      prop  ppt    1000     28    1.42  5.07  2.78 precise       
#> 6 ratings_venue      prop  ppt    1000     29.6  1.44  4.88  2.83 high precision
```
