# Margin of error from a standard error

`z * se`, the half-width of a confidence interval. The default
`z = 1.96` gives an approximate 95% interval; the survey reports used
the `2 * se` rule of thumb, which is `z = 2`.

## Usage

``` r
margin_of_error(se, z = 1.96)
```

## Arguments

- se:

  A standard error (scalar or vector).

- z:

  The critical value / multiplier. Defaults to `1.96` (95%). Use `2` to
  reproduce the report's rule of thumb.

## Value

The `+/-` margin of error, on the same scale as `se`.

## Details

A confidence interval is the estimate plus or minus this margin.
`z = 1.96` gives the standard 95% interval; `z = 2` reproduces the "two
standard errors" rule of thumb often quoted in survey reports;
`z = 2.58` gives 99%. The result is on the same scale as `se`, so for a
proportion error in percentage points, pass
`se_prop(p, n, pctp = TRUE)`.

## See also

[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
margin_of_error(se_prop(0.33, 1184, pctp = TRUE))   # in percentage points
#> [1] 2.678395

margin_of_error(0.02, z = 2)
#> [1] 0.04
```
