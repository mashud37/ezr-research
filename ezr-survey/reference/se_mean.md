# Standard error of a mean (point estimate)

`sd(x) / sqrt(n)`, the sampling error of a mean such as an average 1-5
rating. Packages the inline `sem` calculation from the report appendix.

## Usage

``` r
se_mean(x)
```

## Arguments

- x:

  A numeric vector. `NA` values are ignored.

## Value

A single numeric standard error, or `NA` if fewer than two non-missing
values are present.

## Details

The standard error of the mean is the sample standard deviation divided
by the square root of the (non-missing) sample size, `sd(x) / sqrt(n)`.
It shrinks as the sample grows, and is the basis of the margin of error
you quote for an average rating. Fewer than two values gives `NA` (no
spread to estimate).

## See also

[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
se_mean(c(4, 5, 3, 4, 5, 2, 4))
#> [1] 0.404061
```
