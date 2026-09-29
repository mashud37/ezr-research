# Relative standard error

The standard error expressed as a percentage of the estimate,
`se / estimate * 100`. A common rule of thumb treats an RSE below ~5% as
very good precision.

## Usage

``` r
rse(estimate, se)
```

## Arguments

- estimate:

  The point estimate (mean or proportion).

- se:

  Its standard error, on the same scale as `estimate`.

## Value

The relative standard error, in percent.

## Details

Dividing the standard error by the estimate makes precision comparable
across measures on different scales (a 1–5 rating vs a percentage). A
common rule of thumb treats an RSE under ~5% as very good precision,
which is the threshold
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
uses for its `precision` flag.

## See also

[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
rse(estimate = 4.1, se = se_mean(c(4, 5, 3, 4, 5)))
#> [1] 9.125994
```
