# Standard error of a proportion

`sqrt(p * (1 - p) / n)`, the sampling error of a percentage. Packages
the inline proportion-error calculation from the report appendix.

## Usage

``` r
se_prop(p, n, pctp = FALSE)
```

## Arguments

- p:

  The proportion, either as a fraction in `[0, 1]` or as a percentage in
  `(1, 100]` (values above 1 are divided by 100 automatically).

- n:

  The sample size (number of respondents).

- pctp:

  Return the answer in percentage points instead of on the `[0, 1]`
  proportion scale. Defaults to `FALSE`.

## Value

The standard error of the proportion, on the same `[0, 1]` scale as a
fractional `p`, or in percentage points when `pctp = TRUE`.

## Details

For a percentage from a survey, the sampling error is
`sqrt(p * (1 - p) / n)`. It is largest when `p = 0.5` (a 50/50 split is
the hardest to pin down) and shrinks towards the extremes. The result is
on the same 0–1 scale as a fractional `p`; pass `pctp = TRUE` for
percentage points, the form used in report footnotes and the one
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md)
needs if you want the margin in points. Inputs above 1 are treated as
percentages and divided by 100, so `se_prop(33, n)` and
`se_prop(0.33, n)` agree.

## See also

[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md)

## Examples

``` r
se_prop(0.33, 1184)
#> [1] 0.01366528

se_prop(0.33, 1184, pctp = TRUE)
#> [1] 1.366528
```
