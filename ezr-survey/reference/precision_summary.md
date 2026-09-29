# Plain-language survey precision summary

Distils a whole survey's sampling precision into a few bullet points –
the narrative "Data info" paragraph from the report appendix, generated
automatically. It scans the dataset, assesses the numeric (point-scale)
and categorical (proportion) variables, and reports the typical sampling
margins and an overall reliability verdict.

## Usage

``` r
precision_summary(data = NULL, ..., z = 1.96)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- ...:

  Optional columns to restrict the assessment to (tidyselect). If
  omitted, all suitable columns are used: every numeric column, and
  every categorical column that is not free text or an identifier.

- z:

  Confidence multiplier for the margins of error. Default `1.96` (95%).

## Value

An object of class `ezrsurvey_precision` (a list with `n`, the
per-variable `table`, `overall_rse`, `rating` and the `bullets`).
Printing it shows the bullet points.

## Details

Rather than make you choose which variables to quote precision for, this
picks them: numeric columns become point estimates (margins in rating
points) and categorical columns become proportions (margins in
percentage points), with free-text and id-like columns skipped. It then
reports the **typical** and **worst** margins across each group, plus an
overall verdict from the median relative standard error via
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md).
For proportions it also gives the worst-case `+/-` percentage-point
margin at a 50/50 split, which is the widest any percentage in the study
can be. See
[`vignette("ezrsurvey")`](https://mashud37.github.io/ezr-research/ezr-survey/articles/ezrsurvey.md)
for the rationale behind the relative-standard-error reliability bands.

## See also

[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
precision_summary(podracing_survey)
#> Survey precision summary
#> - Based on 1,000 total responses (per-question base of 776 to 1,000).
#> - Point ratings carry a sampling margin of about +/-0.40 points (up to +/-0.69) at 95% confidence.
#> - Percentages carry a sampling margin of about +/-3.0 percentage points (worst case +/-3.1 at a 50/50 split).
#> - Overall relative standard error of about 4.2% -- high precision.
#> 
```
